 

pragma solidity ^0.4.18;

 

contract Billboard {

    uint public cost = 100000000000000;  
    uint16 public messageSpanStep = 1 minutes;
    address owner;

    bytes32 public head;
    uint public length = 0;
    mapping (bytes32 => Message) public messages;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event MessageAdded(address indexed sender, uint validFrom, uint validTo, string message);
    event MessageSpanStepChanged(uint16 newStep);
    event CostChanged(uint newCost);

    struct Message {
    uint validFrom;
    uint validTo;
    address sender;
    string message;
    bytes32 next;
    }

     
    function Billboard() public {
        _saveMessage(now, now, msg.sender, "Welcome to MyEtheroll.com!");
        owner = msg.sender;
    }

     
    function addMessage(string _message) public payable {
        require(msg.value >= cost || msg.sender == owner);  
        uint validFrom = messages[head].validTo > now ? messages[head].validTo : now;
        _saveMessage(validFrom, validFrom + calculateDuration(msg.value), msg.sender, _message);
        if(msg.value>0)owner.transfer(msg.value);
    }


     
    function getActiveMessage() public view returns (uint, uint, address, string, bytes32) {
        bytes32 idx = _getActiveMessageId();
        return (messages[idx].validFrom, messages[idx].validTo, messages[idx].sender, messages[idx].message, messages[idx].next);
    }

     
    function getQueueOpening() public view returns (uint) {
        return messages[head].validTo;
    }

     
    function calculateDuration(uint _wei) public view returns (uint)  {
        return (_wei / cost * messageSpanStep);
    }

     
    function setMessageSpan(uint16 _newMessageSpanStep) public onlyOwner {
        messageSpanStep = _newMessageSpanStep;
        MessageSpanStepChanged(_newMessageSpanStep);
    }

     
    function setCost(uint _newCost) public onlyOwner {
        cost = _newCost;
        CostChanged(_newCost);
    }

     
    function _saveMessage (uint _validFrom, uint _validTo, address _sender, string _message) private {
        bytes32 id = _createId(Message(_validFrom, _validTo, _sender, _message, head));
        messages[id] = Message(_validFrom, _validTo, _sender, _message, head);
        length = length+1;
        head = id;
        MessageAdded(_sender, _validFrom, _validTo, _message);
    }

     
    function _createId(Message _message) private view returns (bytes32) {
        return keccak256(_message.validFrom, _message.validTo, _message.sender, _message.message, length);
    }

     
    function _getActiveMessageId() private view returns (bytes32) {
        bytes32 idx = head;
        while(messages[messages[idx].next].validTo > now){
            idx = messages[idx].next;
        }
        return idx;
    }

     
    function kill() public onlyOwner {
        selfdestruct(owner);
    }

}