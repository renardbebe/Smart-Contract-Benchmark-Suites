 

pragma solidity ^0.4.16;

 

contract BaseSafeMath {


     



    function add(uint256 a, uint256 b) internal pure

    returns (uint256) {

        uint256 c = a + b;

        assert(c >= a);

        return c;

    }


    function sub(uint256 a, uint256 b) internal pure

    returns (uint256) {

        assert(b <= a);

        return a - b;

    }


    function mul(uint256 a, uint256 b) internal pure

    returns (uint256) {

        uint256 c = a * b;

        assert(a == 0 || c / a == b);

        return c;

    }


    function div(uint256 a, uint256 b) internal pure

    returns (uint256) {

        uint256 c = a / b;

        return c;

    }


    function min(uint256 x, uint256 y) internal pure

    returns (uint256 z) {

        return x <= y ? x : y;

    }


    function max(uint256 x, uint256 y) internal pure

    returns (uint256 z) {

        return x >= y ? x : y;

    }



     



    function madd(uint128 a, uint128 b) internal pure

    returns (uint128) {

        uint128 c = a + b;

        assert(c >= a);

        return c;

    }


    function msub(uint128 a, uint128 b) internal pure

    returns (uint128) {

        assert(b <= a);

        return a - b;

    }


    function mmul(uint128 a, uint128 b) internal pure

    returns (uint128) {

        uint128 c = a * b;

        assert(a == 0 || c / a == b);

        return c;

    }


    function mdiv(uint128 a, uint128 b) internal pure

    returns (uint128) {

        uint128 c = a / b;

        return c;

    }


    function mmin(uint128 x, uint128 y) internal pure

    returns (uint128 z) {

        return x <= y ? x : y;

    }


    function mmax(uint128 x, uint128 y) internal pure

    returns (uint128 z) {

        return x >= y ? x : y;

    }



     



    function miadd(uint64 a, uint64 b) internal pure

    returns (uint64) {

        uint64 c = a + b;

        assert(c >= a);

        return c;

    }


    function misub(uint64 a, uint64 b) internal pure

    returns (uint64) {

        assert(b <= a);

        return a - b;

    }


    function mimul(uint64 a, uint64 b) internal pure

    returns (uint64) {

        uint64 c = a * b;

        assert(a == 0 || c / a == b);

        return c;

    }


    function midiv(uint64 a, uint64 b) internal pure

    returns (uint64) {

        uint64 c = a / b;

        return c;

    }


    function mimin(uint64 x, uint64 y) internal pure

    returns (uint64 z) {

        return x <= y ? x : y;

    }


    function mimax(uint64 x, uint64 y) internal pure

    returns (uint64 z) {

        return x >= y ? x : y;

    }


}


 

 



contract BaseERC20 {

     
    string public name;
    string public symbol;
    uint8 public decimals;
     
    uint256 public totalSupply;

     
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function _transfer(address _from, address _to, uint _value) internal;

     
    function transfer(address _to, uint256 _value) public;

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success);

     
    function burn(uint256 _value) public returns (bool success);

     
    function burnFrom(address _from, uint256 _value) public returns (bool success);

}


 

interface tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;}


contract LockUtils {

    function getLockWFee(address account, uint8 decimals, uint256 createTime, address developer) internal view returns (uint256) {
        uint256 tempLockWFee = 0;
        if (account == developer) {
            if (now < (createTime + 10 minutes)) {
                tempLockWFee = 1500000000 * 10 ** uint256(decimals);
            } else if (now < (createTime + 20 minutes)) {
                tempLockWFee = 1125000000 * 10 ** uint256(decimals);
            } else if (now < (createTime + 30 minutes)) {
                tempLockWFee = 750000000 * 10 ** uint256(decimals);
            } else if (now < (createTime + 40 minutes)) {
                tempLockWFee = 375000000 * 10 ** uint256(decimals);
            }
             
             
             
             
             
             
             
             
             
        }
        return tempLockWFee;
    }

}

contract WFee is BaseERC20, BaseSafeMath, LockUtils {
    string public name = "WFee";
    string public symbol = "WFEE";
    uint8 public decimals = 18; 
    uint256 public totalSupply; 
    uint256 createTime; 
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    address developer;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function WFee() public {
        totalSupply = 10000000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        developer = msg.sender;
        createTime = now;
    }

    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
         
        require((balanceOf[_from] - getLockWFee(_from, decimals, createTime, developer)) >= _value);
         
         
        require((balanceOf[_to] + _value) > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
         
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
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
         
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
         
        require(_value <= allowance[_from][msg.sender]);
         
        balanceOf[_from] -= _value;
         
        allowance[_from][msg.sender] -= _value;
         
        totalSupply -= _value;
         
        Burn(_from, _value);
        return true;
    }

}