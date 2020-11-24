 
contract ContractFallbacks {
    function receiveApproval(address from, uint256 _amount, address _token, bytes memory _data) public;
	function onTokenTransfer(address from, uint256 amount, bytes memory data) public returns (bool success);
}

contract CMLX is ERC20, ERC20Detailed, ERC20Burnable {
     
    constructor () public {
        _name = "China Marshal Lion";        
        _symbol = "CMLX";                    
        _decimals = 18;                      

        _totalSupply = 1000000000000000000000000000;     
        _balances[msg.sender] = _totalSupply;            
        emit Transfer(address(0), msg.sender, _totalSupply);     
    }

     
    function approveAndCall(address _spender, uint256 _amount, bytes calldata _extraData) external returns (bool success)
	{
        require(approve(_spender, _amount), "ERC20: Approve unsuccesfull");
        ContractFallbacks(_spender).receiveApproval(msg.sender, _amount, address(this), _extraData);
        return true;
    }

     
	function transferAndCall(address _to, uint _value, bytes calldata _data) external returns (bool success)
  	{
  	    _transfer(msg.sender, _to, _value);
		return ContractFallbacks(_to).onTokenTransfer(msg.sender, _value, _data);
  	}

}
