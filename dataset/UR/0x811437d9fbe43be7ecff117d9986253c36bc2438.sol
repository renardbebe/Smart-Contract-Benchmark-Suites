 

pragma solidity ^0.4.24;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


contract StandardToken {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
}

contract AirDrop {

    using SafeMath for uint;

    function () payable public {}

     
    function batchTransferToken(address _contractAddress, address[] _addresses, uint _value) public {
         
        require(_addresses.length > 0);

        StandardToken token = StandardToken(_contractAddress);
         
        for (uint i = 0; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], _value);
        }
    }

     
    function batchTransferTokenS(address _contractAddress, address[] _addresses, uint[] _value) public {
         
        require(_addresses.length > 0);
        require(_addresses.length == _value.length);

        StandardToken token = StandardToken(_contractAddress);
         
        for (uint i = 0; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], _value[i]);
        }
    }

     
    function batchTransferETH(address[] _addresses) payable public {
         
        require(_addresses.length > 0);

         
        for (uint i = 0; i < _addresses.length; i++) {
            _addresses[i].transfer(msg.value.div(_addresses.length));
        }
    }

     
    function batchTransferETHS(address[] _addresses, uint[] _value) payable public {
         
        require(_addresses.length > 0);
        require(_addresses.length == _value.length);

         
        for (uint i = 0; i < _addresses.length; i++) {
            _addresses[i].transfer(_value[i]);
        }
    }
}