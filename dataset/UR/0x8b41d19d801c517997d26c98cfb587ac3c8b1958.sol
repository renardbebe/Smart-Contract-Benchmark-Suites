 

 
 

 

 

pragma solidity 0.4.24;


contract Settings {

    address public owner;

    uint public contentCount = 0;
 
     
    mapping (uint => uint) public settings;
    
    event Setting(uint indexed version, uint indexed timePage, uint indexed field, uint value, string dataInfo);

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

    function add(uint _version, uint _field, uint _value, string _dataInfo) public onlyOwner {
        contentCount++;
        settings[_field] = _value;
        emit Setting(_version, block.timestamp / (1 days), _field, _value, _dataInfo);
    }

    function get(uint _field) public constant returns (uint) {
        return settings[_field];
    }
}