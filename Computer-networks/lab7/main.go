// Шлюз: https://www.infura.io/
// https://mainnet.infura.io/v3/8133ff0c11dc491daac3f680d2f74d18
// Посмотреть список блоков https://etherscan.io/
// 0d888590533d48dbab3430c54955ac9d
// https://laba-d6447-default-rtdb.europe-west1.firebasedatabase.app/

package main

import (
	"context"
	"fmt"
	"log"
	"math/big"

	"github.com/zabawaba99/firego"

	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"
)

type Block struct {
	Number       uint64        `json:"Number"`
	Hash         string        `json:"Hash"`
	Time         uint64        `json:"Time"`
	Count        int           `json:"Count"`
	Transactions []Transaction `json:"Transactions"`
}

type Transaction struct {
	Hash     string   `json:"Hash"`
	Value    *big.Int `json:"Value"`
	Cost     *big.Int `json:"Cost"`
	To       string   `json:"To"`
	From     string   `json:"From"`
	Gas      uint64   `json:"Gas"`
	Gasprice *big.Int `json:"Gasprice"`
}

var client *ethclient.Client
var latest uint64
var base *firego.Firebase

func Get() {

	header, err := client.HeaderByNumber(context.Background(), nil)
	if err != nil {
		log.Fatal(err)
	}

	blockNumber := big.NewInt(header.Number.Int64())
	block, err := client.BlockByNumber(context.Background(), blockNumber)
	if err != nil {
		log.Fatal(err)
	}

	var b Block
	b.Number = block.Number().Uint64()
	b.Time = block.Time()
	b.Hash = block.Hash().Hex()
	b.Count = len(block.Transactions())
	if b.Number == latest {
		return
	}

	fmt.Println(b.Number)
	latest = b.Number

	chainID, _ := client.NetworkID(context.Background())
	signer := types.LatestSignerForChainID(chainID)

	var t Transaction
	var Transactions []Transaction
	for _, tx := range block.Transactions() {
		t.Hash = tx.Hash().String()
		t.Value = tx.Value()
		t.Cost = tx.Cost()
		t.To = tx.To().String()
		from, _ := types.Sender(signer, tx)
		t.From = from.Hex()
		t.Gas = tx.Gas()
		t.Gasprice = tx.GasPrice()
		Transactions = append(Transactions, t)
	}

	b.Transactions = Transactions

	_, err = base.Push(b)
	if err != nil {
		log.Fatal(err)
	}
}

func main() {
	var err error
	latest = 0
	client, err = ethclient.Dial("https://mainnet.infura.io/v3/0d888590533d48dbab3430c54955ac9d")
	if err != nil {
		log.Fatalln(err)
	}

	base = firego.New("https://laba-d6447-default-rtdb.europe-west1.firebasedatabase.app/", nil)

	if err := base.Remove(); err != nil {
		log.Fatal(err)
	}

	for {
		Get()
	}

}
