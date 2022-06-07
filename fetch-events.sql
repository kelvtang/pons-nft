create table if not exists events (
    contract_address text,
    contract_name text,
    event_type text,
    data text,
    block_height text
);

create table if not exists latest_block_height (
    height bigint
);

create or replace procedure fetch_event(contract_address text, contract_name text, event_type text, block_height bigint)
language plpgsql
as $$
declare 
    event_record record;
    link text;
begin

    drop table if exists temp_events;
    create table if not exists temp_events(
        contract_address text,
        contract_name text,
        event_type text,
        data text,
        block_height text,
        latest_block_height text
    );

    execute format('COPY temp_events FROM PROGRAM ''/mnt/c/Users/abdel/Desktop/PONS.ai/pons-nft/fetch-events.sh %I %I %I %s''
    WITH (format ''csv'', header ''on'')', contract_address, contract_name, event_type, block_height);

    lock table events in exclusive mode;
    for event_record in select * from temp_events
    loop
        execute 'INSERT INTO events values($1, $2, $3, $4, $5)' 
        using event_record.contract_address, event_record.contract_name, event_record.event_type,
        event_record.data, event_record.data, event_record.block_height;
    end loop;
 
    execute 'INSERT INTO latest_block_height values($1)' using CAST(event_record.latest_block_height as bigint);
    
end$$;

create or replace procedure update_events(contract_address text, contract_name text, event_type text)
language plpgsql
as $$
declare 
    latest_height bigint;
begin
    latest_height := (select max(height) from latest_block_height);
    call fetch_event(contract_address, contract_name, event_type, latest_height);
end$$;


call update_events('1654653399040a61', 'FlowToken', 'TokensWithdrawn');