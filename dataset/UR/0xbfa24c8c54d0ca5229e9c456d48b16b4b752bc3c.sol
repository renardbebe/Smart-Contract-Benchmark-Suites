 

pragma solidity 0.4.26;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }
     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
 
contract ERC20 {
  uint256 public totalSupply;

  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract BillofSaleERC20 {
    using SafeMath for uint256;
    
    string public descr;
    uint256 public price;
    address public tokenContract;
    address public buyer;
    address public seller;
    address public arbiter;
    uint256 public createdAt;
    
    uint256 private arbiterFee;
    
    enum State { Created, Confirmed, Disputed, Resolved }
    State public state;
    
    event Confirmed(address indexed this, address indexed seller);
    event Disputed();
    event Resolved(address indexed this, address indexed buyer, address indexed seller);
     
   constructor(
        string memory _descr,
        uint256 _price,
        address _tokenContract,
        address _buyer,
        address _seller,
        address _arbiter,
        uint256 _arbiterFee)
        public {
                descr = _descr;
                price = _price;
                tokenContract = _tokenContract;
                buyer = _buyer;
                seller = _seller;
                arbiter = _arbiter;
                arbiterFee = _arbiterFee;
                createdAt = now;
                require(price > arbiterFee, "arbiter fee cannot exceed price");
               }
                 
                  modifier onlyBuyer() {
                        require(msg.sender == buyer);
                         _;
                        }
                 
                  modifier onlyBuyerOrSeller() {
                        require(
                        msg.sender == buyer ||
                        msg.sender == seller);
                         _;
                        }
                 
                  modifier onlyArbiter() {
                        require(msg.sender == arbiter);
                         _;
                        }
                 
                  modifier inState(State _state) {
                        require(state == _state);
                         _;
                        }
         
           function confirmReceipt() public onlyBuyer inState(State.Created) {
                state = State.Confirmed;
                ERC20 token = ERC20(tokenContract);
                uint256 tokenBalance = token.balanceOf(this);
                token.transfer(seller, tokenBalance);
                emit Confirmed(address(this), seller);
                }
         
           function initiateDispute() public onlyBuyerOrSeller inState(State.Created) {
                state = State.Disputed;
                emit Disputed();
                }
         
           function resolveDispute(uint256 buyerAward, uint256 sellerAward) public onlyArbiter inState(State.Disputed) {
                state = State.Resolved;
                ERC20 token = ERC20(tokenContract);
                token.transfer(buyer, buyerAward);
                token.transfer(seller, sellerAward);
                token.transfer(arbiter, arbiterFee);
                emit Resolved(address(this), buyer, seller);
                }
}

contract BillofSaleERC20Factory {

   

  mapping (address => bool) public validContracts; 
  address[] public contracts;

   

  function getContractCount() 
    public
    view
    returns(uint contractCount)
  {
    return contracts.length;
  }

   

  function getDeployedContracts() public view returns (address[] memory)
  {
    return contracts;
  }

   

  function newBillofSaleERC20(
      string memory _descr, 
      uint256 _price,
      address _tokenContract,
      address _buyer,
      address _seller, 
      address _arbiter,
      uint256 _arbiterFee)
          public
          returns(address)
   {
    BillofSaleERC20 c = new BillofSaleERC20(
        _descr, 
        _price,
        _tokenContract,
        _buyer, 
        _seller,
        _arbiter,
        _arbiterFee);
            validContracts[c] = true;
            contracts.push(c);
            return c;
    }
}