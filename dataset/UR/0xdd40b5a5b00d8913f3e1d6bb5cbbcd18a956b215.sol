 

pragma solidity ^0.4.18;

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract ERC20Basic {
  uint256 public totalSupply;
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

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}



 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract REPOExchange is MintableToken {

  uint public deal_cancel_rate = 0;

  struct REPODeal {
    address lender;
    address borrower;

    address collateral;
    address pledge;

    uint collateralAmount;
    uint pledgeAmount;

    uint interest;
    uint lenderFee;
    uint borrowerFee;

    uint pledgeUntil;
    uint collateralUntil;
    uint endsAt;

    int state;

     

  }

  event NewDeal(uint dealID, address lender, address borrower, address collateral, address pledge, uint collateralAmount, uint pledgeAmount,
       uint interest, uint lenderFee_, uint borrowerFee_, uint pledgeUntil, uint collateralUntil, uint endsAt);

  event PledgePayed(uint dealID);
  event PledgeNotPayed(uint dealID);
  event PledgePaymentCanceled(uint dealID);

  event CollateralTransfered(uint dealID);
  event CollateralNotTransfered(uint dealID);
  event CollateralTransferCanceled(uint dealID);

  event CollateralReturned(uint dealID);
  event CollateralNotReturned(uint dealID);

  event DealCancelRate(uint dealCancelRate);

  function setDealCancelRate(uint deal_cancel_rate_) public {
    require(msg.sender == owner);
    deal_cancel_rate = deal_cancel_rate_;
    DealCancelRate(deal_cancel_rate);
  }

  function getDealCancelRate() public constant returns (uint _deal_cancel_rate) {
    return deal_cancel_rate;
  }


  uint lastDealID;
  mapping (uint => REPODeal) deals;

  function REPOExchange() public {
  }

  function() public {
    revert();
  }

  function newDeal(address lender_, address borrower_, address collateral_, address pledge_, uint collateralAmount_, uint pledgeAmount_,
    uint interest_, uint lenderFee_, uint borrowerFee_, uint pledgeUntil_, uint collateralUntil_, uint endsAt_) public returns (uint dealID) {
    require(msg.sender == owner);
    dealID = lastDealID++;
    deals[dealID] = REPODeal(lender_, borrower_, collateral_, pledge_, collateralAmount_, pledgeAmount_,
      interest_, lenderFee_, borrowerFee_, pledgeUntil_, collateralUntil_, endsAt_, 0);

    NewDeal(dealID, lender_, borrower_, collateral_, pledge_, collateralAmount_, pledgeAmount_,
      interest_, lenderFee_, borrowerFee_, pledgeUntil_, collateralUntil_, endsAt_);
  }

  function payPledge(uint dealID) public payable {
    REPODeal storage deal = deals[dealID];
    require(deal.state == 0);
    require(block.number < deal.pledgeUntil);
    require(msg.sender == deal.borrower);

    uint payment = deal.pledgeAmount + deal.borrowerFee;
    if (deal.pledge == 0) {
      require(msg.value == payment);
    } else {
      require(ERC20(deal.pledge).transferFrom(msg.sender, this, payment));
    }
     
    deal.state = 1;
    PledgePayed(dealID);
  }

  function cancelPledgePayment(uint dealID) public {
    REPODeal storage deal = deals[dealID];
    require(deal.state == 0);
    require(msg.sender == deal.borrower);
    require(this.transferFrom(msg.sender, owner, deal_cancel_rate));
    deal.state = -10;
    PledgePaymentCanceled(dealID);
  }

  function notifyPledgeNotPayed(uint dealID) public {
    REPODeal storage deal = deals[dealID];
    require(deal.state == 0);
    require(block.number >= deal.pledgeUntil);
    deal.state = -1;
    PledgeNotPayed(dealID);
  }

  function transferCollateral(uint dealID) public payable {
    REPODeal storage deal = deals[dealID];
    require(deal.state == 1);
    require(block.number < deal.collateralUntil);
    require(msg.sender == deal.lender);

    uint payment = deal.collateralAmount + deal.lenderFee;
    if (deal.collateral == 0) {
      require(msg.value == payment);
      require(deal.borrower.send(deal.collateralAmount));
      require(owner.send(deal.lenderFee));
    } else {
      require(ERC20(deal.collateral).transferFrom(msg.sender, deal.borrower, deal.collateralAmount));
      require(ERC20(deal.collateral).transferFrom(msg.sender, owner, deal.lenderFee));
    }

    sendGoods(deal.pledge, owner, deal.borrowerFee);

    deal.state = 2;
    CollateralTransfered(dealID);
  }

  function cancelCollateralTransfer(uint dealID) public {
    REPODeal storage deal = deals[dealID];
    require(deal.state == 1);
    require(msg.sender == deal.lender);
    require(this.transferFrom(msg.sender, owner, deal_cancel_rate));

    sendGoods(deal.pledge, deal.borrower, deal.pledgeAmount + deal.borrowerFee);

    deal.state = -20;
    CollateralTransferCanceled(dealID);
  }

  function notifyCollateralNotTransfered(uint dealID) public {
    REPODeal storage deal = deals[dealID];
    require(deal.state == 1);
    require(block.number >= deal.collateralUntil);

    sendGoods(deal.pledge, deal.borrower, deal.pledgeAmount + deal.borrowerFee);

    deal.state = -2;
    CollateralNotTransfered(dealID);
  }

  function sendGoods(address goods, address to, uint amount) private {
    if (goods == 0) {
      require(to.send(amount));
    } else {
      require(ERC20(goods).transfer(to, amount));
    }
  }

  function returnCollateral(uint dealID) public payable {
    REPODeal storage deal = deals[dealID];
    require(deal.state == 2);
    require(block.number < deal.endsAt);
    require(msg.sender == deal.borrower);

    uint payment = deal.collateralAmount + deal.interest;
    if (deal.collateral == 0) {
      require(msg.value == payment);
      require(deal.lender.send(msg.value));
    } else {
      require(ERC20(deal.collateral).transferFrom(msg.sender, deal.lender, payment));
    }

    sendGoods(deal.pledge, deal.borrower, deal.pledgeAmount);

    deal.state = 3;
    CollateralReturned(dealID);
  }

  function notifyCollateralNotReturned(uint dealID) public {
    REPODeal storage deal = deals[dealID];
    require(deal.state == 2);
    require(block.number >= deal.endsAt);

    sendGoods(deal.pledge, deal.lender, deal.pledgeAmount);

    deal.state = -3;
    CollateralNotReturned(dealID);
  }
}