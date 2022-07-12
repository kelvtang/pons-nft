create or replace procedure fetch_events(block_height bigint)
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
    execute format('copy temp_events from program ''/mnt/c/Users/abdel/Desktop/PONS.ai/pons-nft/gosdk/fetch-events.sh %s'' with (format ''csv'', header ''on'')', block_height);
    -- execute format('copy temp_events from program ''/home/ubuntu/abdel/gosdk/fetch-events.sh %s'' with (format ''csv'', header ''on'')', block_height);

    lock table events in exclusive mode;
    
    for event_record in select * from temp_events
    loop
        if event_record.new_event = 'true' then
            execute 'INSERT INTO events values($1, $2, $3, $4, $5, $6)' 
            using event_record.contract_address, event_record.contract_name, event_record.event_type, event_record.transaction_id,
            event_record.data, event_record.block_height;
        end if;
    end loop;
 
    execute 'INSERT INTO latest_block_height values($1)' using event_record.latest_block_height;
    
end$$;

create or replace procedure update_events()
language plpgsql
as $$
declare 
    latest_height bigint;
begin
    latest_height := (select max(height) from latest_block_height);
    call fetch_events(latest_height);
end$$;


call fetch_events(22349785);
-- call update_events();
