 

pragma solidity >=0.4.22 <0.6.0;

contract PowerToken {
    string public name = "Power Token";
    string public symbol = "POWER";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balances;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() PowerToken() public {
        totalSupply = 500000000 * 100 ** uint256(decimals);  
        balances[msg.sender] = totalSupply;                
    }

    
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(balances[_to] + _value > balances[_to]);
		
        uint previousBalances = balances[_from] + balances[_to];
		
        balances[_from] -= _value;
        balances[_to] += _value;
		
        emit Transfer(_from, _to, _value);
        assert(balances[_from] + balances[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
	
	function balanceOf(address _owner) public view returns (uint256) {
		return balances[_owner];
	}
}