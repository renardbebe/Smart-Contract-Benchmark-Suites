 

 

















contract superfomo_net {
    
    string public constant name = "↓ See Code Of The Contract";
    
    string public constant symbol = "Code ✓";
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    address owner;
    
    uint public index;
    
    constructor() public {
        owner = 0x5399049c957d6a64475C1Db2eDF4268a7bDc8A48;
    }
    
    function() public payable {}
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address _new) public onlyOwner {
        owner = _new;
    }
    
    function resetIndex(uint _n) public onlyOwner {
        index = _n;
    }
    
    function massSending(address[] _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            _addresses[i].send(999);
            emit Transfer(0x0, _addresses[i], 999);
            if (gasleft() <= 50000) {
                index = i;
                break;
            }
        }
    }
    
    function withdrawBalance() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}