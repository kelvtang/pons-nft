package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strconv"
	"strings"

	"github.com/onflow/flow-go-sdk"
	"github.com/onflow/flow-go-sdk/client"
	"google.golang.org/grpc"
	// "github.com/onflow/flow-go-sdk/access/grpc"
)

func main() {
	ctx := context.Background()

	opts := []grpc.DialOption{
		grpc.WithInsecure(),
		grpc.WithBlock(),
		grpc.WithDefaultCallOptions(grpc.MaxCallRecvMsgSize(20 * 1024 * 1024)),
	}

	// initialize client
	c, err := client.New("access-001.mainnet16.nodes.onflow.org:9000", opts...)
	// flowClient, err := grpc.NewClient("access-001.mainnet15.nodes.onflow.org:9000")
	handleError(err)

	// Get starting block height
	signedHeight, err := strconv.ParseInt(os.Args[1], 10, 64)
	handleError(err)
	startHeight := uint64(signedHeight)

	signedEndHeight, err := strconv.ParseInt(os.Args[2], 10, 64)
	handleError(err)
	endHeight := uint64(signedEndHeight) - 1
	// var endHeight uint64
	// latestBlock, err := c.GetLatestBlock(ctx, true)
	// handleError(err)
	// endHeight = latestBlock.Height

	// Different channels
	collectionChannel := make(chan collectionPayload)
	transactionChannel := make(chan transactionPayload)
	eventsChannel := make(chan eventPayload)

	// Our final array that holds all relevant events
	var eventsData []event

	for startHeight < endHeight {
		var blockHeights []uint64

		if startHeight+99 <= endHeight {
			for j := startHeight; j < startHeight+100; j++ {
				blockHeights = append(blockHeights, j)
			}
			startHeight += 100
		} else {
			for j := startHeight; j <= endHeight; j++ {
				blockHeights = append(blockHeights, j)
			}
			startHeight = endHeight
		}

		for _, height := range blockHeights {
			go getBlockCollections(height, collectionChannel, ctx, c)
		}

		collectionGuarantees := make([]collectionPayload, len(blockHeights))

		for i := range collectionGuarantees {
			collectionGuarantees[i] = <-collectionChannel

			for _, collection := range collectionGuarantees[i].collectionGuarantees {
				go getCollectionTransactions(collectionGuarantees[i].height, collection.CollectionID, transactionChannel, ctx, c)

			}

			collectionTransactions := make([]transactionPayload, len(collectionGuarantees[i].collectionGuarantees))

			for i := range collectionTransactions {
				collectionTransactions[i] = <-transactionChannel
				for _, transactionId := range collectionTransactions[i].transactionIDs {
					go getTransactionsEvents(collectionTransactions[i].height, transactionId, eventsChannel, ctx, c)
				}
				// fmt.Println(collectionTransactions[i].transactionIDs)
				transactionEvents := make([]eventPayload, len(collectionTransactions[i].transactionIDs))

				for i := range transactionEvents {
					transactionEvents[i] = <-eventsChannel

					for _, e := range transactionEvents[i].events {
						if strings.HasPrefix(e.Value.EventType.QualifiedIdentifier, "Pons") {
							// fmt.Println(e)
							// fmt.Println(e.Value.EventType.Fields)
							eventData := make(map[string]string)
							for k, v := range e.Value.EventType.Fields {
								eventData[v.Identifier] = e.Value.Fields[k].String()
							}
							// fmt.Println(eventData)
							eventInformation, _ := json.MarshalIndent(eventData, "", " ")
							values := strings.SplitN(e.Value.String(), "(", 2)
							eventType := strings.Split(values[0], ".")
							payload := event{
								Contract_address:    eventType[1],
								Contract_name:       eventType[2],
								Event_type:          eventType[3],
								Transaction_id:      e.TransactionID.String(),
								Data:                string(eventInformation),
								Block_height:        transactionEvents[i].height,
								Latest_block_height: endHeight,
								New_event:           true,
							}
							eventsData = append(eventsData, payload)
						}
					}
				}
			}
		}
	}
	if len(eventsData) == 0 {
		emptyJson, _ := json.MarshalIndent("", "", " ")
		payload := event{
			Contract_address:    "",
			Contract_name:       "",
			Event_type:          "",
			Transaction_id:      "",
			Data:                string(emptyJson),
			Block_height:        endHeight,
			Latest_block_height: endHeight,
			New_event:           false,
		}
		eventsData = append(eventsData, payload)
	}
	responseMap := make(map[string][]event)
	responseMap["events"] = eventsData
	eventsJson, _ := json.MarshalIndent(responseMap, "", " ")
	fmt.Println(string(eventsJson))
}

func getBlockCollections(height uint64, collectionChannel chan collectionPayload, ctx context.Context, c *client.Client) {

	blockInformation, err := c.GetBlockByHeight(ctx, height)
	handleError(err)
	payload := collectionPayload{
		height:               blockInformation.Height,
		collectionGuarantees: blockInformation.CollectionGuarantees,
	}
	collectionChannel <- payload
}

func getCollectionTransactions(height uint64, collectionId flow.Identifier, transactionChannel chan transactionPayload, ctx context.Context, c *client.Client) {
	collectionInformation, err := c.GetCollection(ctx, collectionId)
	handleError(err)
	payload := transactionPayload{
		height:         height,
		transactionIDs: collectionInformation.TransactionIDs,
	}
	transactionChannel <- payload
}

func getTransactionsEvents(height uint64, transactionId flow.Identifier, eventChannel chan eventPayload, ctx context.Context, c *client.Client) {
	transactionInformation, err := c.GetTransactionResult(ctx, transactionId)
	handleError(err)
	payload := eventPayload{
		height: height,
		events: transactionInformation.Events,
	}
	eventChannel <- payload
}

func handleError(err error) {
	if err != nil {
		panic(err)
	}
}

type collectionPayload struct {
	height               uint64
	collectionGuarantees []*flow.CollectionGuarantee
}

type transactionPayload struct {
	height         uint64
	transactionIDs []flow.Identifier
}

type eventPayload struct {
	height uint64
	events []flow.Event
}

type event struct {
	Contract_address    string `json:"contract_address"`
	Contract_name       string `json:"contract_name"`
	Event_type          string `json:"event_type"`
	Transaction_id      string `json:"transaction_id"`
	Data                string `json:"data"`
	Block_height        uint64 `json:"block_height"`
	Latest_block_height uint64 `json:"latest_block_height"`
	New_event           bool   `json:"new_event"`
}
