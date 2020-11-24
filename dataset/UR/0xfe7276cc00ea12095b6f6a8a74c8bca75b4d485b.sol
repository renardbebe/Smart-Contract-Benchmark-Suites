 

pragma solidity ^0.5.1;

contract RubyToken{
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) private transferable;
    
    uint256 private _totalSupply=10000000000000000000000000000;
    string private _name= "RubyToken";
    string private _symbol= "RUBY";
    uint256 private _decimals = 18;
    address private _administrator = msg.sender;
    
    constructor () public {
            balanceOf[msg.sender] = _totalSupply;
        }

        
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(balanceOf[_from]>=_value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(transfercheck(_from) == true);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
    }
    
    function transfer(address to, uint256 value) public {
        _transfer(msg.sender, to, value);
    }
    
    function transfercheck(address check) internal returns(bool) {
        if (transferable[check]==false){
            return true;
        }
        return false;
    }
    
    
    function lock(address lockee) public {
        require(msg.sender == _administrator);
        transferable[lockee] = true;
    }
    
    function unlock(address unlockee) public {
        require(msg.sender == _administrator);
        transferable[unlockee] = false;
    }
    
    function lockcheck(address checkee) public view returns (bool){
        return transferable[checkee];
    }
    
    
    function _burn(address account, uint256 value) private {
        require(account == _administrator);
        require(msg.sender == _administrator);
        require(account != address(0), "ERC20: burn from the zero address");
        require(balanceOf[account]>value);
        require(_totalSupply>value);
        _totalSupply -= value;
        balanceOf[account] -=value;
    }
    
    function _addsupply(address account, uint256 value) private {
        require(account == _administrator);
        require(msg.sender == _administrator);
        _totalSupply += value;
        balanceOf[account] +=value;
    }
    
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
    
    function addsupply(uint256 amount) public {
        _addsupply(msg.sender, amount);
    }
    
}