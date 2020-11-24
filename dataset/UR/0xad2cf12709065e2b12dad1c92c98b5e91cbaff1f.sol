 

pragma solidity ^0.5.4;

 


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Hut34DIT is ERC20 {
  uint constant MAX_UINT = 2**256 - 1;

  string  public constant name            = "Hut34 Discrete Information Theory";
  string  public constant symbol          = "DIT";
  uint8   public constant decimals        = 18;

  function totalSupply() public view returns (uint) {
    return MAX_UINT;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return MAX_UINT;
  }

  function transfer(address _to, uint _value) public returns (bool)  {
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return MAX_UINT;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    emit Transfer(_from, _to, _value);
    return true;
  }

 

    mapping(address => string) private dataOne;

    function addDataOne(string memory _data) public {
        dataOne[msg.sender] = _data;
    }

    function getDataOne(address who) public view returns (string memory) {
        return dataOne[who];
    }

mapping(address => string) private dataTwo;

    function addDataTwo(string memory _data) public {
        dataTwo[msg.sender] = _data;
    }

    function getDataTwo(address who) public view returns (string memory) {
        return dataTwo[who];
    }

mapping(address => string) private dataThree;

    function addDataThree(string memory _data) public {
        dataThree[msg.sender] = _data;
    }

    function getDataThree(address who) public view returns (string memory) {
        return dataThree[who];
    }

mapping(address => string) private dataFour;

    function addDataFour(string memory _data) public {
        dataFour[msg.sender] = _data;
    }

    function getDataFour(address who) public view returns (string memory) {
        return dataFour[who];


}
}