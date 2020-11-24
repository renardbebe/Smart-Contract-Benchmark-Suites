 

pragma solidity ^0.4.24;

 
 

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Erc2Vite {
    
    mapping (address => string) public records;
    
    address public destoryAddr = 0x1111111111111111111111111111111111111111;

    uint256 public defaultCode = 203226;
    
    address public viteTokenAddress = 0x0;
	address public owner			= 0x0;
	
	uint public bindId = 0;
	event Bind(uint bindId, address indexed _ethAddr, string _viteAddr, uint256 amount, uint256 _invitationCode);
	
	 
	 
	 
	 
	function Erc2Vite(address _viteTokenAddress, address _owner) {
		require(_viteTokenAddress != address(0));
		require(_owner != address(0));

		viteTokenAddress = _viteTokenAddress;
		owner = _owner;
	}
    
    function bind(string _viteAddr, uint256 _invitationCode) public {

        require(bytes(_viteAddr).length == 55);
        
        var viteToken = Token(viteTokenAddress);
        uint256 apprAmount = viteToken.allowance(msg.sender, address(this));
        require(apprAmount > 0);
        
        require(viteToken.transferFrom(msg.sender, destoryAddr, apprAmount));
        
        records[msg.sender] = _viteAddr;

        if(_invitationCode == 0) {
            _invitationCode = defaultCode;
        }
        
        emit Bind(
            bindId++,
            msg.sender,
            _viteAddr,
            apprAmount,
            _invitationCode
        );
    }
    
    function () public payable {
        revert();
    }
    
    function destory() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
    
}