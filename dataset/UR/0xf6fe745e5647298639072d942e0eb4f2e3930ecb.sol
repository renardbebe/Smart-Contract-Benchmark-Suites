 

pragma solidity ^ 0.4.24;

contract TokenName {
	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Consume(address indexed from, uint256 value);
}

contract BaseContract is TokenName{
	using SafeMath
	for * ;
	
	string public name = "FK token";
    string public symbol = "FK";
    uint8 public decimals = 18;
    uint256 public totalSupply = 900000000000000000000000000;
    mapping (address => uint256) public balance;
    mapping (address => mapping (address => uint256)) public allowance;
    address public manager;
    address public releaseAddress = 0x2458f120fc75d7d5d3b07c074a096eb0eacd16d3;
    uint256 public createTime;
    uint256 public takeTotal = 0;
	function BaseContract(
        ) {
        manager = msg.sender;
        balance[msg.sender] = 100000000000000000000000000;
        createTime = now;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success){
    	require(_to != 0x0, "invalid addr");
    	if(msg.sender == releaseAddress){
    		uint256 _releaseTotal = releaseTotal();
    		if(_releaseTotal != takeTotal){
				balance[msg.sender] = balance[msg.sender].add(_releaseTotal.sub(takeTotal));
				takeTotal = _releaseTotal;
    		}
		}
        balance[msg.sender] = balance[msg.sender].sub(_value);
        balance[_to] = balance[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != 0x0, "invalid addr");
		require(_value > 0, "invalid value");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
     	require(_from != 0x0, "invalid addr");
        require(_to != 0x0, "invalid addr");
        balance[_from] = balance[_from].sub(_value);
        balance[_to] = balance[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
     
    function consume(uint256 _value) public returns (bool success){
     	require(msg.sender == manager, "invalid addr");
     	balance[msg.sender] = balance[msg.sender].sub(_value);
     	emit Consume(msg.sender, _value);
     	return true;
    }
    
    function releaseTotal()
    public
    view
    returns(uint256){
    	uint256 _now = now;
    	uint256 _time = _now.sub(createTime);
    	uint256 _years = _time/31536000;
    	uint256 _release = 200000000000000000000000000;
    	uint256 _total = 0;
    	for(uint256 i = 0; i <= _years; i++){
    		if(i != 0 && i%2 == 0){
    			_release = _release/2;
    		}
    		if(i == _years){
    			_total = _total.add((_time.sub(i.mul(31536000))/86400).mul(_release/365));
    		}else{
    			_total = _total.add(_release);
    		}
    	}
    	if(_total >= 800000000000000000000000000){
    		_total = 800000000000000000000000000;
    	}
    	return _total;
    }
    
    function release()
    public
	view
	returns(uint256){
    	uint256 _now = now;
    	uint256 _time = _now.sub(createTime);
    	uint256 _count = _time/63072000;
    	uint256 _release = 200000000000000000000000000;
    	for(uint256 i = 0; i < _count; i++){
    		_release = _release/2;
    	}
    	return _release/365;
    }
    
    function balanceOf(address _addr)
	public
	view
	returns(uint256) {
		if(_addr == releaseAddress){
			return balance[_addr].add(releaseTotal().sub(takeTotal));
		}
		return balance[_addr];
	}
    
}

library SafeMath {
	
	function mul(uint256 a, uint256 b)
	internal
	pure
	returns(uint256 c) {
		if(a == 0) {
			return 0;
		}
		c = a * b;
		require(c / a == b, "mul failed");
		return c;
	}

	function sub(uint256 a, uint256 b)
	internal
	pure
	returns(uint256 c) {
		require(b <= a, "sub failed");
		c = a - b;
		require(c <= a, "sub failed");
		return c;
	}

	function add(uint256 a, uint256 b)
	internal
	pure
	returns(uint256 c) {
		c = a + b;
		require(c >= a, "add failed");
		return c;
	}

}