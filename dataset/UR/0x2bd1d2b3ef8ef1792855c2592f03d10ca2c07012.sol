 

  function transfer(address _to, uint256 _value) transferable public returns (bool){

  	require(_to != address(0));
  	require(_value <= balanceOf[msg.sender]);
  	balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
  	balanceOf[_to] = balanceOf[_to].add(_value);
  	emit Transfer(msg.sender, _to, _value);
  	return true;
  }


 

function transferFrom(address _from, address _to, uint256 _value) transferable public returns (bool) {
	

	require(_value <= allowance[_from][msg.sender]);
	allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
	balanceOf[_from] = balanceOf[_from].sub(_value);
	balanceOf[_to] = balanceOf[_to].add(_value);
	emit Transfer(_from, _to, _value);
	return true;
}

 
function approve(address _spender, uint256 _value) public returns (bool) {
	require(!blacklist[_spender] && !blacklist[msg.sender]);
	allowance[msg.sender][_spender] = _value;
	emit Approval(msg.sender, _spender, _value);
	return true;

}

function burn(uint256 _value) public returns (bool) {
	require(!blacklist[msg.sender]);
	require(balanceOf[msg.sender] >= _value);
	balanceOf[msg.sender] =balanceOf[msg.sender].sub(_value);
	totalSupply = totalSupply.sub(_value);
	emit Burn(msg.sender, _value);
	return true;
}


 
function addToBlacklist(address addr) public {
	require(msg.sender == admin);
	blacklist[addr] = true;
}
 
function removeFromBlacklist(address addr) public {
	require(msg.sender == admin);
	blacklist[addr] = false;
}

function addToWhitelist(address addr) public {
	require(msg.sender == admin);
	whitelist[addr] = true;
}
function removeFromWhitelist(address addr) public {
	require(msg.sender == admin);
	whitelist[addr] = false;
}


 
modifier transferable(){
	require(!transferPaused || whitelist[msg.sender] || msg.sender == admin);
	require(!blacklist[msg.sender]);
	_;
}

 
function unpauseTransfer() public {
	require(msg.sender == admin);
	transferPaused = false;
}

 
function transferOwnership(address newOwner) public {
	require(msg.sender == admin);
	admin = newOwner;
} 

}