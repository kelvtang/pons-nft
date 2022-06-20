create table if not exists events (
    contract_address text,
    contract_name text,
    event_type text,
    transaction_id text,
    data jsonb,
    block_height bigint
);

create table if not exists latest_block_height (
    height bigint
);

create or replace procedure fetch_events(block_height bigint, end_height bigint default -1)
language plpgsql
as $$
declare 
    event_record record;
begin

    create temp table temp_events(
        contract_address text,
        contract_name text,
        event_type text,
        transaction_id text,
        data jsonb,
        block_height bigint,
        latest_block_height bigint,
        new_event boolean
    );
    execute format('copy temp_events from program ''/mnt/c/Users/abdel/Desktop/PONS.ai/pons-nft/gosdk/fetch-events.sh %s %s'' with (format ''csv'', header ''on'')', block_height, end_height);

    lock table events in exclusive mode;
    
    for event_record in select * from temp_events
    loop
        if event_record.new_event = 'true' then
            execute 'INSERT INTO events values($1, $2, $3, $4, $5, $6)' 
            using event_record.contract_address, event_record.contract_name, event_record.event_type, event_record.transaction_id,
            event_record.data, event_record.block_height;
        end if;
    end loop;
 
    -- execute 'INSERT INTO latest_block_height values($1)' using CAST(event_record.latest_block_height as bigint);
    
end$$;

create or replace procedure update_events()
language plpgsql
as $$
declare 
    latest_height bigint;
begin
    latest_height := (select max(height) from latest_block_height);
    call fetch_event(latest_height);
end$$;


call fetch_events(30801493, 30801494);


