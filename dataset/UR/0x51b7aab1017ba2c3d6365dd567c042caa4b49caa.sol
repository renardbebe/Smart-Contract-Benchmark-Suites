 

pragma solidity ^0.4.16;


contract Token3CC {
     

    mapping (address => uint256) public balanceOf;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    string public name = "3CC";

    string public symbol = "3CC";

    uint8 public decimals = 8;

    uint256 public initialSupply = 2200000000 * (10 ** uint256(decimals));

    address public owner;

     
    function Token3CC() public {
        owner = msg.sender;
        balanceOf[msg.sender] = initialSupply;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }



     
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
         
        Transfer(_from, _to, _value);
    }

     
     
     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

}