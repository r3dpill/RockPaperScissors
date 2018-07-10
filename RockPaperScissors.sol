pragma solidity ^0.4.24;

import './Stoppable.sol';

contract RockPaperScissors is Stoppable {
    
    uint public playerCount;
    uint public bidAmount;
    uint public payout;
    address public winnerAddress;
    uint32[3][3] public winnerMatrix;
    
    struct PlayerBid {
        address player;
        uint amount;
        uint paid;
        uint8 choice;
    }
    
    mapping(uint => PlayerBid) public playerBids;
    
    modifier IsOpen() {
        require(getPlayerCount() < 2);
        _;
    }
    
    event LogPlayerBid(address player, uint amount, uint8 choice);
    event LogPayout(address player, uint amount);
    
    constructor(uint bid) public {
        owner = msg.sender;
        bidAmount = bid;
        winnerMatrix[0][0] = 0;
        winnerMatrix[0][1] = 2;
        winnerMatrix[0][2] = 1;
        winnerMatrix[1][0] = 1;
        winnerMatrix[1][1] = 0;
        winnerMatrix[1][2] = 2;
        winnerMatrix[2][0] = 2;
        winnerMatrix[2][1] = 1;
        winnerMatrix[2][2] = 0;
    }
    
    function placeBid(uint8 choice) public payable IsOpen {
        require(msg.value == bidAmount);
        playerCount += 1;
        payout += msg.value;
        playerBids[playerCount].player = msg.sender;
        playerBids[playerCount].amount = msg.value;
        playerBids[playerCount].choice = choice;
        emit LogPlayerBid(msg.sender, msg.value, choice);
        if(getPlayerCount() == 2) {
            payWinner();
        }
    }
    
    function payWinner() public {
        address payTo;
        uint toSend;
        
        require(getPlayerCount() == 2);
        uint winner = winnerMatrix[playerBids[1].choice][playerBids[2].choice];
        if(winner == 0) {
            for(uint i=1; i<=2; i++) {
                payTo = playerBids[i].player;
                toSend = playerBids[1].amount - playerBids[i].paid;
                playerBids[i].paid = toSend;
                makePayment(payTo, toSend);
            }
        } else {
            payTo = playerBids[winner].player;
            toSend = payout;
            playerBids[winner].paid = toSend;
            makePayment(payTo, toSend);
            winnerAddress = payTo;
            payout -= toSend;
        }
    }
    
    function makePayment(address payee, uint amount)
        public
        returns(bool success)
        {
            require(payee.send(amount));
            emit LogPayout(payee, amount);
            return true;
        }
    
    function getPlayerCount() public view returns(uint players) {
        return(playerCount);
    }
}
