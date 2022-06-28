import fetch from "cross-fetch";
import { ethers } from "ethers";
import { ethereum_network, ethereum_private_key } from "./config.mjs";

//  To get arguments from the bash script
const args = process.argv.slice(2);

const send_log_request_ = async (filter, arr, provider) => {
    try {
        var logs = await provider.getLogs(filter)
        return [filter.toBlock + 1, logs]
    } catch (e) {
        filter.toBlock = Math.floor((filter.fromBlock + filter.toBlock) / 2)
        return await send_log_request_(filter, arr, provider)
    }
}

const fetch_logs_ = async (startBlock, contractAddress) => {
    const provider = new ethers.providers.JsonRpcProvider(ethereum_network)

    var latestBlockNum = await provider.getBlockNumber()

    var request_filter = {
        fromBlock: null,
        toBlock: null,
        address: null
    }

    request_filter.address = contractAddress

    var logs = []
    //limit of 10k logs
    while (startBlock <= latestBlockNum) {
        request_filter.fromBlock = startBlock
        request_filter.toBlock = latestBlockNum
        const resp = await send_log_request_(request_filter, logs, provider)
        startBlock = resp[0]
        logs = [...logs, ...resp[1]]
    }


    logs = logs.map(log => {
        return {
            address: log.address,
            topics: JSON.stringify(log.topics.map(topic => topic.slice(2))),
            data: log.data.slice(2),
            blockNumber: log.blockNumber,
            blockHash: log.blockHash,
            logIndex: log.logIndex,
            removed: log.removed,
            transactionHash: log.transactionHash,
            transactionIndex: log.transactionIndex,
            latestBlockNumer: latestBlockNum + 1     
        }
    })

    if (logs.length > 0) {
        console.log(JSON.stringify({ logs: logs }))
    } else {
        console.log(JSON.stringify({
            logs: {
                address: null,
                topics: null,
                data: null,
                blockNumber: null,
                blockHash: null,
                logIndex: null,
                removed: null,
                transactionHash: null,
                transactionIndex: null,
                latestBlockNumer: latestBlockNum + 1,
            }
        }))
    }

}

fetch_logs_(parseInt(args[0]), args[1])