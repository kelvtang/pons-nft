import fetch from "cross-fetch";


//  Etherscan's api key goes here
const apiKey = ""

//  To get arguments from the bash script
const args = process.argv.slice(2);

//  gets the latest block height on the blockChain
const fetchLatestBlock = async () => {
    const URL = `https://api.etherscan.io/api?module=proxy&action=eth_blockNumber&apikey=${apiKey}`
    const response = await fetch(URL)
    const blockNum = await response.json()
    return parseInt((blockNum.result.slice(2)), 16)
}

/* 
    This function is used when we have over 1000 logs.
    What happens is that the etherscan api can only return 1000 logs per request
    In case we have more than 1000 logs, we can't know if we fetched all the logs in the last block or not
    Therefore we use binarySearch to find the first log in the last block and return its index
    See below on how it is used
*/
const binarySearch = (arr, x) => {
    let l = 0;
    let r = arr.length - 1;
    let mid;
    while (r >= l) {
        mid = l + Math.floor((r - l) / 2);
        if (arr[mid].blockNumber === x) {
            /*
                since we can have more than one log in the same block
                When instance is found, keep moving backwards in case there are still logs with the same block number
                keep going backwards until we reach a block with different block number
                increment by one and return index
            */
            while (arr[mid].blockNumber === x && mid !== -1) {
                mid--
            }
            mid += 1
            return mid;
        }



        if (arr[mid].blockNumber > x)
            r = mid - 1;

        else
            l = mid + 1;
    }

    // We reach here when element is not
    // present in array
    return -1;
}

const fetchLogs = async (startBlock, contractAddress, startFrom = 0) => {

    var logs = []

    var latestBlockNum = await fetchLatestBlock()

    while (startBlock <= latestBlockNum) {
        const URL = `https://api.etherscan.io/api?module=logs&action=getLogs&fromBlock=${startBlock}&toBlock=${latestBlockNum}
        &address=${contractAddress}&apikey=${apiKey}`
        const response = await fetch(URL)
        const payload = await response.json()
        const logsParsed = payload.result.map(log => {
            // slicing is done to remove the '0x' from certain columns as it will not be needed
            // parseInt(hexValue, 16) returns the number value equivalnet to the hex string
            const blockNumber = parseInt(log.blockNumber.slice(2), 16)
            const timeStamp = new Date(parseInt((log.timeStamp.slice(2)), 16) * 1000)
            const gasPrice = parseInt(log.gasPrice.slice(2), 16)
            const gasUsed = parseInt(log.gasUsed.slice(2), 16)
            const logIndex = parseInt(log.logIndex.slice(2), 16)
            const transactionIndex = parseInt(log.transactionIndex.slice(2), 16)
            const topics = log.topics.map(topic => topic.slice(2))
            const data = log.data.slice(2)
            return {
                address: log.address,
                topics: JSON.stringify(topics), // for batch script to be able to store as string in csv format
                data: data,
                blockNumber: blockNumber,
                date: timeStamp,
                gasPrice: gasPrice,
                gasUsed: gasUsed,
                logIndex: logIndex,
                transactionHash: log.transactionHash,
                transactionIndex: transactionIndex,
                latestBlockNumer: latestBlockNum + 1, // next time we start searching from lastBlock + 1 since fetching is inclusive
            }
        })

        // startFrom is initially 0, if more than 1000 logs then we might need to offset some logs
        // Errors could happen from this method, like missing a log or duplicating logs so anything below could be source of errors
        logs = [...logs, ...(logsParsed.slice(startFrom))]

        if (logsParsed.length === 1000) {
            const arrayLength = logsParsed.length
            const lastLog = logsParsed[arrayLength - 1]
            const lastBlockNumber = lastLog.blockNumber
            // get index of first log in the lastblock read
            const lastBlockNumberFirstEntry = binarySearch(logsParsed, lastBlockNumber)

            // subtract from 1000 to offset to the new logs that have not been stored before
            startFrom = 1000 - lastBlockNumberFirstEntry

            // start from last block again and use offset to store only new logs
            startBlock = lastBlockNumber
        } else {
            break
        }
    }
    if (logs.length > 0) {
        console.log(JSON.stringify({ logs: logs }))
    } else {
        console.log(JSON.stringify({
            logs: {
                address: null,
                topics: null,
                data: null,
                blockNumber: null,
                date: null,
                gasPrice: null,
                gasUsed: null,
                logIndex: null,
                transactionHash: null,
                transactionIndex: null,
                latestBlockNumer: latestBlockNum + 1,
            }
        }))
    }

}

fetchLogs(args[0], args[1])