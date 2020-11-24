 

pragma solidity ^0.4.23;

import "./Ownable.sol";
import "./PausableToken.sol";
import "./SafeMath.sol";

 

contract TokenNET is Ownable, PausableToken {
    string constant public name = "Out Coin";
    string constant public symbol = "OUT";
     
    uint8 constant public decimals = 18;  


     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

      
    constructor() public {
        totalSupply_ = (430 * 10 ** 6) * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply_;
    }

     
    function burn(uint256 _value) public whenNotPaused {
        _burn(msg.sender, _value);
    }

     
    function burnFrom(address _from, uint256 _value) public whenNotPaused {
        require(_value <= allowed[_from][msg.sender]);
       
       
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Approval(_from, msg.sender, allowed[_from][msg.sender]);
        _burn(_from, _value);
    }

    function _burn(address _who, uint256 _value) internal whenNotPaused{
        require(_value <= balances[_who]);
       
       

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}
