 

pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract DateTime {
		function toTimestamp(uint16 year, uint8 month, uint8 day) public constant returns (uint timestamp);
        function getYear(uint timestamp) public constant returns (uint16);
        function getMonth(uint timestamp) public constant returns (uint8);
        function getDay(uint timestamp) public constant returns (uint8);
}

contract TokenERC20 {
     
    string public name = "Authpaper Coin";
    string public symbol = "AUPC";
    uint8 public decimals = 18;
     
    uint256 public totalSupply = 400000000 * 10 ** uint256(decimals);
	address public owner;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
	mapping (address => uint256) public icoAmount;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);
	
	 
	address public dateTimeAddr = 0x1a6184CD4C5Bea62B0116de7962EE7315B7bcBce;
	DateTime dateTime = DateTime(dateTimeAddr);
	uint[] lockupTime = [dateTime.toTimestamp(2018,9,15),dateTime.toTimestamp(2018,10,15),dateTime.toTimestamp(2018,11,15),
	dateTime.toTimestamp(2018,12,15),dateTime.toTimestamp(2019,1,15),dateTime.toTimestamp(2019,2,15),
	dateTime.toTimestamp(2019,3,15),dateTime.toTimestamp(2019,4,15),dateTime.toTimestamp(2019,5,15),
	dateTime.toTimestamp(2019,6,15),dateTime.toTimestamp(2019,7,15),dateTime.toTimestamp(2019,8,15),
	dateTime.toTimestamp(2019,9,15)];
	uint lockupRatio = 8;
	uint fullTradeTime = dateTime.toTimestamp(2019,10,1);

     
    constructor() public {
        balanceOf[msg.sender] = totalSupply;                 
		owner = msg.sender;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
		require( balanceOf[_to] + _value >= balanceOf[_to] );
		require( 100*(balanceOf[_from] - _value) >= (balanceOf[_from] - _value) );
		require( 100*icoAmount[_from] >= icoAmount[_from] );
		require( icoAmount[_to] + _value >= icoAmount[_to] );
		
		if(now < fullTradeTime && _from != owner && _to !=owner && icoAmount[_from] >0) {
			 
			uint256 i=0;
			for (uint256 l = lockupTime.length; i < l; i++) {
				if(now < lockupTime[i]) break;
			}
			uint256 minAmountLeft = (i<1)? 0 : ( (lockupRatio*i>100)? 100 : lockupRatio*i );
			minAmountLeft = 100 - minAmountLeft;
			require( ((balanceOf[_from] - _value)*100) >= (minAmountLeft*icoAmount[_from]) );			
		}	
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
		if(_from == owner && now < fullTradeTime) icoAmount[_to] += _value;
		if(_to == owner){
			if(icoAmount[_from] >= _value) icoAmount[_from] -= _value;
			else icoAmount[_from]=0;
		}
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
	function addApprove(address _spender, uint256 _value) public returns (bool success){
		require( allowance[msg.sender][_spender] + _value >= allowance[msg.sender][_spender] );
		allowance[msg.sender][_spender] += _value;
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
		return true;
	}
	function claimICOToken() public returns (bool success){
		require(allowance[owner][msg.sender] > 0);      
		transferFrom(owner,msg.sender,allowance[owner][msg.sender]);
		return true;
	}
	

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
}