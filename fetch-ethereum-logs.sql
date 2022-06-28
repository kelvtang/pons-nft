create table if not exists logs (
    address text references contract,
    topics jsonb not null,
    data bytea,
    block_number bigint not null,
    block_hash text,
    log_index numeric,
    removed boolean,
    transaction_hash text not null,
    transaction_index numeric
);

create table if not exists latest_block_height (
    height bigint,
    address text references contract,
    primary key(address, height)
);

create table if not exists contract (
    address text not null,
    primary key(address)
);

create or replace procedure fetch_logs(block_height bigint, contract_address text)
language plpgsql
as $$
declare 
    log_record record;
    latest_height bigint;
begin

    create temp table temp_events(
        address text,
        topics jsonb not null,
        data bytea,
        block_number bigint not null,
        block_hash text,
        log_index numeric,
        removed boolean,
        transaction_hash text not null,
        transaction_index numeric,
        latest_block_number bigint
    );
    execute format('copy temp_events from program ''/mnt/c/Users/abdel/Desktop/PONS.ai/pons-nft/fetch-ethereum-logs.sh %s %s'' with (format ''csv'', header ''on'')', block_height, contract_address);

    lock table logs in exclusive mode;
    for log_record in select * from temp_events
    loop
        if log_record.transaction_hash is not null then
            execute 'INSERT INTO logs values($1, $2, $3, $4, $5, $6, $7, $8, $9)' 
            using log_record.address, log_record.topics, log_record.data, log_record.block_number,
            log_record.block_hash, log_record.log_index, log_record.removed, log_record.transaction_hash,
            log_record.transaction_index;
        end if;
    end loop;

    latest_height := (select latest_block_number from temp_events limit 1 );
    execute 'INSERT INTO latest_block_height values($1, $2)' using latest_height, contract_address;
    
end$$;

create or replace procedure update_events()
language plpgsql
as $$
declare 
    latest_height bigint;
    contract_address text;
begin
    for contract_address in select address from contract
    loop
        latest_height := (select max(height) from latest_block_height where address = contract_address);
        call fetch_logs(latest_height, contract_address);
    end loop;
end$$;


-- How to use:
-- First, we need to insert all contract addresses into the contracts table

-- Next, we need to insert the initial starting block height with the addresses into the latest block height table, this can be done
-- by either inserting it manually to the table or calling the fetch_logs procedure which inserts the information as well as the logs

-- finally, can call the update_events automatically and all information will be fetched from the db and updated


-- Simple calls:
-- call update_events()
call fetch_logs(14038339, '0x1657E2200216ebAcB92475b69D6BC0FdAD48B068');

