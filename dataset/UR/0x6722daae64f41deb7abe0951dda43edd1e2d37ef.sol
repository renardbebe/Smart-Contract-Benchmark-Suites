 

pragma solidity ^0.4.24;

contract Proxy{
    address owner;
    address forwardingAddress;
    uint cap;
    address feeAddress;
    bool public isComplete;

    event ForwardFunds(address indexed _recipient, uint _amount);
    event ReceivedFunds(address indexed _sender, uint _amount);
    event ForwardFee(address indexed _feeAddress, uint _amount);

    modifier onlyOwner{
        require(msg.sender == owner, "Only the owner may edit this contract");
        _;
    }

    constructor(address _forwardingAddress, address _feeAddress, uint256 _cap) public{
        require(_feeAddress != address(0), "Cannot initialise without a fee address");
        require(_cap >= 0, "Cap cannot be less that 0");
        require(_forwardingAddress != address(0), "Cannot initialise without a forwarding address");
         
        uint32 size;
        assembly {
            size := extcodesize(_forwardingAddress)
        }
        require(size == 0, "Cannot set contract as forwarding address");

        owner = msg.sender;
        forwardingAddress = _forwardingAddress;
        feeAddress = _feeAddress;
        cap = _cap;
        isComplete = false;
    }

     
    function() public payable {
        require(!isComplete, "This dump has completed!");
         
        emit ReceivedFunds(msg.sender, msg.value);
    }

    function complete() public onlyOwner {
        require(!isComplete, "This dump has already raised the required ether.");  
        uint owedToRecipient = address(this).balance - (address(this).balance / 10);
        uint fee = address(this).balance / 10;
        forwardingAddress.transfer(owedToRecipient);
        feeAddress.transfer(fee);
        isComplete = true;
        emit ForwardFunds(forwardingAddress, owedToRecipient);
        emit ForwardFee(feeAddress, fee);
    }

}