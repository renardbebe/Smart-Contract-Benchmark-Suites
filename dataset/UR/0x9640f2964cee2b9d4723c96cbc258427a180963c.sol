 

pragma solidity ^0.4.23;

 
 
 
 
 
 
 

contract EthernalMessageBook {

    event MessageEthernalized(
        uint messageId
    );

    struct Message {
        string msg;
        uint value;
        address sourceAddr;
        string authorName;
        uint time;
        uint blockNumber;
        string metadata;
        string link;
        string title;
    }

    Message[] public messages;

    address private root;

    uint public price;
    uint public startingPrice;

    uint32 public multNumerator;
    uint32 public multDenominator;

    uint32 public expirationSeconds;
    uint public expirationTime;

    constructor(uint argStartPrice, uint32 argNumerator, uint32 argDenominator, uint32 argExpirationSeconds) public {
        root = msg.sender;
        price = argStartPrice;
        startingPrice = argStartPrice;

        require(argNumerator > multDenominator);
        multNumerator = argNumerator;
        multDenominator = argDenominator;

        expirationSeconds = argExpirationSeconds;
        expirationTime = now;
    }

    function getMessagesCount() public view returns (uint) {
        return messages.length;
    }

    function getSummary() public view returns (uint32, uint32, uint, uint) {
        return (
            multNumerator,
            multDenominator,
            startingPrice,
            messages.length
        );
    }


    function getSecondsToExpiration() public view returns (uint) {
        if (expirationTime > now) {
            return expirationTime - now;
        }
        else return 0;
    }


    function writeMessage(string argMsg, string argTitle, string argAuthorName, string argLink, string argMeta) public payable {
        require(block.timestamp >= expirationTime);
        require(msg.value >= price);
        Message memory newMessage = Message({
            msg : argMsg,
            value : msg.value,
            sourceAddr : msg.sender,
            authorName : argAuthorName,
            time : block.timestamp,
            blockNumber : block.number,
            metadata : argMeta,
            link : argLink,
            title: argTitle
        });
        messages.push(newMessage);
        address thisContract = this;
        root.transfer(thisContract.balance);
        emit MessageEthernalized(messages.length - 1);
        price = (price * multNumerator) / multDenominator;
        expirationTime = block.timestamp + expirationSeconds;
}

     
}