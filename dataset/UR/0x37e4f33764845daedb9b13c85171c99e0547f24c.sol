 

 
 

 

 

pragma solidity 0.4.24;


contract MiniMeToken {

     
     
     
     
    function transfer(address _to, uint256 _amount) public returns (bool success);

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success);
}


contract Store {

     
    uint16 constant internal NONE = 0;
    uint16 constant internal ADD = 1;
    uint16 constant internal CANCEL = 2;

    address public owner;
    uint public contentCount = 0;
    
    event LogStore(uint indexed version, address indexed sender, uint indexed timePage,
        uint16 eventType, uint timeSpan, string dataInfo);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }

     
    function () public {
        revert();
    }

    function kill() public onlyOwner {

        selfdestruct(owner);
    }

    function flush() public onlyOwner {

        if (!owner.send(address(this).balance))
            revert();
    }

    function flushToken(address _tokenAddress) public onlyOwner {

        MiniMeToken token = MiniMeToken(_tokenAddress);
        uint balance = token.balanceOf(this);

        if (!token.transfer(owner, balance))
            revert();
    }

    function add(uint _version, uint16 _eventType, uint _timeSpan, string _dataInfo) public {
        contentCount++;
        emit LogStore(_version, msg.sender, block.timestamp / (1 days), _eventType, _timeSpan, _dataInfo);
    }
}