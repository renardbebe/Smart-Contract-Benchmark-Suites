 

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
 
 

interface IERC1620 {
     
    event Create(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    );

     
     
     
    event Withdraw(uint256 indexed streamId, address indexed recipient, uint256 amount);

     
     
    event Cancel(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 senderAmount,
        uint256 recipientAmount
    );

     
     
     
     
     
     
     
     
     
    function create(address recipient, uint256 deposit, address tokenAddress, uint256 startTime, uint256 stopTime)
        external
        returns (uint256 streamId);

     
     
     
     
     
     
     
    function withdraw(uint256 streamId, uint256 funds) external;

     
     
     
     
     
     
     
    function cancel(uint256 streamId) external;

     
     
     
     
     
     
    function balanceOf(uint256 streamId, address who) external view returns (uint256 balance);

     
     
     
    function getStream(uint256 streamId)
        external
        view
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address token,
            uint256 startTime,
            uint256 stopTime,
            uint256 balance,
            uint256 rate
        );
}

 

library Types {
    struct Stream {
        uint256 balance;
        uint256 deposit;
        bool isEntity;
        uint256 rate;
        address recipient;
        address sender;
        uint256 startTime;
        uint256 stopTime;
        address tokenAddress;
    }
}

 

pragma solidity 0.5.10;






 
 

contract Sablier is IERC1620, Ownable {
    using SafeMath for uint256;

    mapping(uint256 => Types.Stream) private streams;
    uint256 public nonce;

    modifier onlyRecipient(uint256 streamId) {
        require(streams[streamId].recipient == msg.sender, "caller is not the recipient of the stream");
        _;
    }

    modifier onlySenderOrRecipient(uint256 streamId) {
        require(
            msg.sender == streams[streamId].sender || msg.sender == streams[streamId].recipient,
            "caller is not the stream or the recipient of the stream"
        );
        _;
    }

    modifier streamExists(uint256 streamId) {
        require(streams[streamId].isEntity, "stream does not exist");
        _;
    }

    constructor() public {
        nonce = 1;
    }

    function balanceOf(uint256 streamId, address who) public view streamExists(streamId) returns (uint256 balance) {
        Types.Stream memory stream = streams[streamId];
        uint256 delta = deltaOf(streamId);
        uint256 streamed = delta.mul(stream.rate);
        if (stream.balance != stream.deposit) {
            streamed = streamed.sub(stream.deposit.sub(stream.balance));
        }
        if (who == stream.recipient) {
            return streamed;
        } else if (who == stream.sender) {
            return stream.balance.sub(streamed);
        } else {
            return 0;
        }
    }

    function deltaOf(uint256 streamId) public view streamExists(streamId) returns (uint256 delta) {
        Types.Stream memory stream = streams[streamId];

         
        if (block.timestamp <= stream.startTime) return 0;

         
        if (block.timestamp < stream.stopTime) return block.timestamp - stream.startTime;

         
        return stream.stopTime - stream.startTime;
    }

    function getStream(uint256 streamId)
        external
        view
        streamExists(streamId)
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 balance,
            uint256 rate
        )
    {
        Types.Stream memory stream = streams[streamId];
        return (
            stream.sender,
            stream.recipient,
            stream.deposit,
            stream.tokenAddress,
            stream.startTime,
            stream.stopTime,
            stream.balance,
            stream.rate
        );
    }

    function create(address recipient, uint256 deposit, address tokenAddress, uint256 startTime, uint256 stopTime)
        external
        returns (uint256 streamId)
    {
        require(recipient != address(0x00), "stream to the zero address");
        require(recipient != address(this), "stream to the contract itself");
        require(recipient != msg.sender, "stream to the caller");
        require(deposit > 0, "deposit is zero");
        require(startTime >= block.timestamp, "start time before block.timestamp");
        require(stopTime > startTime, "stop time before the start time");
        require(deposit.mod(stopTime.sub(startTime)) == 0, "deposit not multiple of time delta");

        streamId = nonce;
        address sender = msg.sender;
        uint256 rate = deposit.div(stopTime.sub(startTime));
        streams[streamId] = Types.Stream({
            balance: deposit,
            deposit: deposit,
            isEntity: true,
            rate: rate,
            recipient: recipient,
            sender: sender,
            startTime: startTime,
            stopTime: stopTime,
            tokenAddress: tokenAddress
        });

        emit Create(streamId, sender, recipient, deposit, tokenAddress, startTime, stopTime);

        nonce = nonce.add(1);
        require(IERC20(tokenAddress).transferFrom(sender, address(this), deposit), "token transfer failure");
    }

    function withdraw(uint256 streamId, uint256 amount) external streamExists(streamId) onlyRecipient(streamId) {
        require(amount > 0, "amount is zero");
        Types.Stream memory stream = streams[streamId];
        uint256 balance = balanceOf(streamId, stream.recipient);
        require(balance >= amount, "withdrawal exceeds the available balance");

        streams[streamId].balance = streams[streamId].balance.sub(amount);
        emit Withdraw(streamId, stream.recipient, amount);

         
        if (streams[streamId].balance == 0) delete streams[streamId];

         
        require(IERC20(stream.tokenAddress).transfer(stream.recipient, amount), "token transfer failure");
    }

    function cancel(uint256 streamId) external streamExists(streamId) onlySenderOrRecipient(streamId) {
        Types.Stream memory stream = streams[streamId];
        uint256 senderAmount = balanceOf(streamId, stream.sender);
        uint256 recipientAmount = balanceOf(streamId, stream.recipient);

        emit Cancel(streamId, stream.sender, stream.recipient, senderAmount, recipientAmount);

         
        delete streams[streamId];

         
        if (recipientAmount > 0)
            require(
                IERC20(stream.tokenAddress).transfer(stream.recipient, recipientAmount),
                "recipient token transfer failure"
            );
        if (senderAmount > 0)
            require(IERC20(stream.tokenAddress).transfer(stream.sender, senderAmount), "sender token transfer failure");
    }
}