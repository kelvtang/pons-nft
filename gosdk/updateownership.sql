create type escrowContractStatus as enum ('Submitted', 'Consummated', 'Terminated', 'Dismissed');

drop table if exists nft cascade;
drop table if exists account cascade;
drop table if exists nft_ownership cascade;
drop table if exists escrow_contract cascade;
drop table if exists events cascade;
drop table if exists latest_block_height cascade;

create table if not exists events (
    contract_address text,
    contract_name text,
    event_type text,
    transaction_id text,
    data jsonb,
    block_height bigint
);

create table if not exists nft (
    nft_id text,
    serial_number numeric not null,
    artist_id text,
    royalties_ratio numeric,
    edition_label text,
    metadata jsonb,
    is_listed boolean,
    price numeric,
    primary key(nft_id)
);

create table if not exists account (
    address text,
    primary key(address)
);

create table if not exists nft_ownership (
    nft_id text references nft not null,
    serial_number numeric not null,
    account_address text references account(address),
    since_transaction_id text not null,
    until_transaction_id text
);


create table if not exists escrow_contract (
    contract_id text,
    account_address text references account(address),
    held_resource_description jsonb,
    requirement jsonb,
    fulfilled_Resource_Description jsonb,
    status escrowContractStatus,
    primary key(contract_id)
);

create trigger update_nft_ownership
    after insert 
    on events
    for each row 
execute function address_trigger();


create or replace function address_trigger() returns trigger as $update_nft_ownership$
declare 
    nftId text;
    serial_number numeric;
    artist_id text;
    edition_label text;
    metadata jsonb;
    accountAddress text;
    transaction_id text;
    royalty numeric;
    nft_price numeric;
begin

    if new.event_type = 'PonsEscrowSubmitted' then

        if  new.data->'address' is not null then
            insert into account values(new.data->>'address') on conflict do nothing;
        end if;

        insert into escrow_contract values(new.data->>'id',new.data->>'address', new.data->'heldResourceDescription',
        new.data->'requirement', null, 'Submitted');

    elsif new.event_type = 'PonsEscrowConsummated' then
        update escrow_contract
        set status = 'Consummated', fulfilled_Resource_Description = new.data->'fulfilledResourceDescription'
        where contract_id = new.data->>'id';

    elsif new.event_type = 'PonsEscrowDismissed' then

        update escrow_contract
        set status = 'Dismissed'
        where contract_id = new.data->>'id';

    elsif new.event_type = 'PonsEscrowTerminated' then

        update escrow_contract
        set status = 'Terminated'
        where contract_id = new.data->>'id';

    elsif new.event_type = 'PonsNftMinted' then
        nftId := new.data->>'nftId';
        serial_number := new.data->>'serialNumber';
        artist_id := new.data->>'artistId';
        royalty := trim(')' from (split_part(new.data->>'royalty', ' ', 2)));
        edition_label := new.data->>'editionLabel';
        metadata := new.data->'metadata';
        insert into nft values(nftId, serial_number, artist_id, royalty, edition_label, metadata, false, null);

    elsif new.event_type = 'PonsNftWithdrawFromCollection' or new.event_type = 'PonsNftDepositToCollection' then
        nftId := new.data->>'nftId';
        serial_number := new.data->>'serialNumber';
        accountAddress := new.data->>'to';
        transaction_id := new.transaction_id;

        if accountAddress is not null then
            insert into account values(accountAddress) on conflict do nothing;
        end if;

        if new.event_type = 'PonsNftWithdrawFromCollection' then
            update nft_ownership
            set until_transaction_id = transaction_id
            where nft_id = nftId and until_transaction_id is null;
        elsif new.event_type = 'PonsNftDepositToCollection' then
            insert into nft_ownership values(nftId, serial_number, accountAddress, transaction_id, null);
        end if;

    elseif new.event_type = 'PonsNFTListed' then
        nft_price :=  trim(')' from (split_part(new.data->>'price', ' ', 2)));
        update nft
        set is_listed = true, price = nft_price
        where nft_id = new.data->>'nftId';

    elseif new.event_type = 'PonsNFTUnlisted' or new.event_type = 'PonsNFTOwns' or new.event_type = 'PonsNFTSold' then 

        update nft
        set is_listed = false, price = null
        where nft_id = new.data->>'nftId';

    end if;

    return new;
end;
$update_nft_ownership$ language plpgsql;