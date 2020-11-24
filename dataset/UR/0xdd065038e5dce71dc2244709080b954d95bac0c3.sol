 

pragma solidity ^0.4.24;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


    
contract MultiSig is IERC20 {
    address private addrA;
    address private addrB;
    address private addrC;
    address private addrToken;

    struct Permit {
        bool addrAYes;
        bool addrBYes;
        bool addrCYes;
    }
    
    mapping (address => mapping (uint => Permit)) private permits;
    
     event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    uint public totalSupply = 10*10**26;
    uint8 constant public decimals = 18;
    string constant public name = "MutiSigPTN";
    string constant public symbol = "MPTN";

 function approve(address spender, uint256 value) external returns (bool){
     return false;
 }

    function transferFrom(address from, address to, uint256 value) external returns (bool){
        return false;
    }

    function totalSupply() external view returns (uint256){
          IERC20 token = IERC20(addrToken);
          return token.totalSupply();
    }


    function allowance(address owner, address spender) external view returns (uint256){
        return 0;
    }
    
    constructor(address a, address b,address c, address tokenAddress) public{
        addrA = a;
        addrB = b;
        addrC = c;
        addrToken = tokenAddress;
    }
    function getAddrs() public view returns(address, address, address,address) {
      return (addrA, addrB, addrC,addrToken);
    }
    function  transfer(address to,  uint amount)  public returns (bool){
        IERC20 token = IERC20(addrToken);
        require(token.balanceOf(this) >= amount);

        if (msg.sender == addrA) {
            permits[to][amount].addrAYes = true;
        } else if (msg.sender == addrB) {
            permits[to][amount].addrBYes = true;
        } else if (msg.sender == addrC) {
            permits[to][amount].addrCYes = true;
        } else {
            require(false);
        }

        if (permits[to][amount].addrAYes == true && permits[to][amount].addrBYes == true && permits[to][amount].addrCYes == true) {
            token.transfer(to, amount);
            permits[to][amount].addrAYes = false;
            permits[to][amount].addrBYes = false;
            permits[to][amount].addrCYes = false;
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    function balanceOf(address _owner) public view returns (uint) {
        IERC20 token = IERC20(addrToken);
        if (_owner==addrA || _owner==addrB || _owner==addrC){
            return token.balanceOf(this);
        }
        return 0;
    }
}