 

pragma solidity ^0.4.24;


 
      
 
 
 
 
 
 
 
 
 


contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function balanceOf(address who) public view returns (uint256);
    function approve(address spender, uint tokens) public returns (bool success);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Buy(address to, uint amount);
    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );
    event onGoldAccountWithdraw(
        uint256 ethereumWithdrawn
    );
    event onOpAccountWithdraw(
        uint256 ethereumWithdrawn
    );
    event onTokenSale(
        address indexed customerAddress,
        uint256 amount
    );
    event onTokenRedeem(
        address indexed customerAddress,
        uint256 amount
    );
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

library SafeMath {

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) 
        {
     
     
     
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

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

   
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

   
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

   
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract MultiSigTransfer is Ownable {
  string public name = "MultiSigTransfer";
  string public symbol = "MST";
  bool public complete = false;
  bool public denied = false;
  uint256 public quantity;
  address public targetAddress;
  address public requesterAddress;

   
  constructor(
    uint256 _quantity,
    address _targetAddress,
    address _requesterAddress
  ) public {
    quantity = _quantity;
    targetAddress = _targetAddress;
    requesterAddress = _requesterAddress;
  }

   
  function approveTransfer() public onlyOwner {
    require(denied == false, "cannot approve a denied transfer");
    require(complete == false, "cannot approve a complete transfer");
    complete = true;
  }

   
  function denyTransfer() public onlyOwner {
    require(denied == false, "cannot deny a transfer that is already denied");
    denied = true;
  }

   
  function isPending() public view returns (bool) {
    return !complete;
  }
}

contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    view
    public
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    view
    public
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

contract GuardianGoldToken is BasicToken, Ownable, RBAC {
    string public name = "GuardianGoldToken";
    string public symbol = "GGT";
    uint8 public decimals = 18;
    string public constant ADMIN_ROLE = "ADMIN";

    uint256 constant internal magnitude = 2**64;

    uint public maxTokens = 5000e18;

    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => mapping (address => uint256)) allowed;

    uint public goldAccount = 0;
    uint public operationsAccount = 0;

    uint256 internal profitPerShare_;

    address[] public transfers;

    uint public constant INITIAL_SUPPLY = 62207e15; 
    uint public totalSupply = 62207e15;
    uint public totalGoldReserves = 62207e15;
    uint public pendingGold = 0;
    uint public totalETHReceived = 57.599 ether;

    bool public isTransferable = true;
    bool public toggleTransferablePending = false;
    address public transferToggleRequester = address(0);

    uint public tokenPrice = 0.925925 ether;
    uint public goldPrice = 0.390185 ether;

    uint public tokenSellDiscount = 950;   
    uint public referralFee = 30;   

    uint minGoldPrice = 0.2 ether;
    uint maxGoldPrice = 0.7 ether;

    uint minTokenPrice = 0.5 ether;
    uint maxTokenPrice = 2 ether;

    uint public dividendRate = 150;   


    uint public minPurchaseAmount = 0.1 ether;
    uint public minSaleAmount = 1e18;    
    uint public minRefStake = 1e17;   

    bool public allowBuy = false;
    bool public allowSell = false;
    bool public allowRedeem = false;



    constructor() public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        addRole(msg.sender, ADMIN_ROLE);
        emit Transfer(address(this), msg.sender, INITIAL_SUPPLY);
    }


    function buy(address _referredBy) 

      payable 
      public  

      {
          require(msg.value >= minPurchaseAmount);
          require(allowBuy);
           
           
          uint newTokens = ethereumToTokens_(msg.value);

          totalETHReceived = SafeMath.add(totalETHReceived, msg.value);

          require(SafeMath.add(totalSupply, newTokens) <= maxTokens);

          balances[msg.sender] = SafeMath.add(balances[msg.sender], newTokens);
          totalSupply = SafeMath.add(newTokens, totalSupply);

          uint goldAmount = SafeMath.div(SafeMath.mul(goldPrice,msg.value),tokenPrice);
          uint operationsAmount = SafeMath.sub(msg.value,goldAmount);

          uint256 _referralBonus = SafeMath.div(SafeMath.mul(operationsAmount, referralFee),1000);

          goldAccount = SafeMath.add(goldAmount, goldAccount);
          uint _dividends = SafeMath.div(SafeMath.mul(dividendRate, operationsAmount),1000);

          if(
             
            _referredBy != 0x0000000000000000000000000000000000000000 &&
            _referredBy != msg.sender &&
            balances[_referredBy] >= minRefStake)
            {
                operationsAmount = SafeMath.sub(operationsAmount,_referralBonus);
                 
                referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
            }

          uint256 _fee = _dividends * magnitude;
          profitPerShare_ += (_dividends * magnitude / (totalSupply));
          _fee = _fee - (_fee-(newTokens * (_dividends * magnitude / (totalSupply))));
          int256 _updatedPayouts = (int256) ((profitPerShare_ * newTokens) - _fee);

          payoutsTo_[msg.sender] += _updatedPayouts;
          operationsAmount = SafeMath.sub(operationsAmount, _dividends);
          operationsAccount = SafeMath.add(operationsAccount, operationsAmount);

          pendingGold = SafeMath.add(pendingGold, newTokens);
          emit Buy(msg.sender, newTokens);
          emit Transfer(address(this), msg.sender, newTokens);
    
    }

    function sell(uint amount) 

      public
  
      {

        require(allowSell);
        require(amount >= minSaleAmount);
        require(balances[msg.sender] >= amount);

         
        uint256 _ethereum = tokensToEthereum_(amount);
        require(_ethereum <= operationsAccount);
         
        totalSupply = SafeMath.sub(totalSupply, amount);

        if (pendingGold > amount) {
            pendingGold = SafeMath.sub(pendingGold, amount);
        }else{
            pendingGold = 0;
        }

        balances[msg.sender] = SafeMath.sub(balances[msg.sender], amount);

         
        int256 _updatedPayouts = (int256) (profitPerShare_ * amount + (_ethereum * magnitude));
        payoutsTo_[msg.sender] -= _updatedPayouts;    

        operationsAccount = SafeMath.sub(operationsAccount, _ethereum);  
        emit onTokenSale(msg.sender, amount); 
    }


    function redeemTokensForGold(uint amount)

    public
    {
         
        require(allowRedeem);
        require(balances[msg.sender] >= amount);
        if(myDividends(true) > 0) withdraw();

        payoutsTo_[msg.sender] -= (int256) (profitPerShare_ * amount);

        balances[msg.sender] = SafeMath.sub(balances[msg.sender], amount);
        totalSupply = SafeMath.sub(totalSupply, amount);
        emit onTokenRedeem(msg.sender, amount);
    }


    function getTokenAmount(uint amount) public 
    
    returns(uint)

    {
        return (amount*1e18)/(tokenPrice);
    }

    function depositGold()
      public
      payable
    {
        goldAccount = SafeMath.add(goldAccount, msg.value);
    }

    function depositOperations()
      public
      payable
    {
        operationsAccount = SafeMath.add(operationsAccount, msg.value);
    }

  
    function tokensToEthereum_(uint256 _tokens)
       internal
        view
        returns(uint256)
    {
        uint liquidPrice = SafeMath.div(SafeMath.mul(goldPrice, tokenSellDiscount),1000);
        uint256 _etherReceived = SafeMath.div(_tokens * liquidPrice, 1e18);
        return _etherReceived;
    }

    function ethereumToTokens_(uint256 _ethereum)
        public
        view
        returns(uint256)
    {
        uint256 _tokensReceived = SafeMath.div(_ethereum*1e18, tokenPrice);
            
        return _tokensReceived;
    }

    function updateGoldReserves(uint newReserves)
    public
    onlyRole(ADMIN_ROLE)
    {
        totalGoldReserves = newReserves;
        if (totalSupply > totalGoldReserves) {
            pendingGold = SafeMath.sub(totalSupply,totalGoldReserves);
        }else{
            pendingGold = 0;
        }
    }

    function setTokenPrice(uint newPrice)
      public
      onlyRole(ADMIN_ROLE)
    {
        require(newPrice >= minTokenPrice);
        require(newPrice <= maxTokenPrice);
        tokenPrice = newPrice;
    }

    function setGoldPrice(uint newPrice)
      public
      onlyRole(ADMIN_ROLE)
    {
        require(newPrice >= minGoldPrice);
        require(newPrice <= maxGoldPrice);
        goldPrice = newPrice;
    }

    function setTokenRange(uint newMax, uint newMin)
        public
        onlyRole(ADMIN_ROLE)
        {
            minTokenPrice = newMin;
            maxTokenPrice = newMax;
        }

    function setmaxTokens(uint newMax)
      public
      onlyRole(ADMIN_ROLE)
      {
          maxTokens = newMax;
      }

    function setGoldRange(uint newMax, uint newMin)
      public
      onlyRole(ADMIN_ROLE)
      {
        minGoldPrice = newMin;
        maxGoldPrice = newMax;
      }

    function withDrawGoldAccount(uint amount)
        public
        onlyRole(ADMIN_ROLE)
        {
          require(amount <= goldAccount);
          goldAccount = SafeMath.sub(goldAccount, amount);
          msg.sender.transfer(amount);
        }

      function withDrawOperationsAccount(uint amount)
          public
          onlyRole(ADMIN_ROLE)
          {
            require(amount <= operationsAccount);
            operationsAccount = SafeMath.sub(operationsAccount, amount);
            msg.sender.transfer(amount);
          }

      function setAllowBuy(bool newAllow)
          public
          onlyRole(ADMIN_ROLE)
          {
            allowBuy = newAllow;
          }

      function setAllowSell(bool newAllow)
          public
          onlyRole(ADMIN_ROLE)
          {
            allowSell = newAllow;
          }

      function setAllowRedeem(bool newAllow)
          public
          onlyRole(ADMIN_ROLE)
          {
            allowRedeem = newAllow;
          }

      function setMinPurchaseAmount(uint newAmount)
          public 
          onlyRole(ADMIN_ROLE)
      {
          minPurchaseAmount = newAmount;
      } 

      function setMinSaleAmount(uint newAmount)
          public 
          onlyRole(ADMIN_ROLE)
      {
          minSaleAmount = newAmount;
      } 

      function setMinRefStake(uint newAmount)
          public 
          onlyRole(ADMIN_ROLE)
      {
          minRefStake = newAmount;
      } 

      function setReferralFee(uint newAmount)
          public 
          onlyRole(ADMIN_ROLE)
      {
          referralFee = newAmount;
      } 

      function setProofofStakeFee(uint newAmount)
          public 
          onlyRole(ADMIN_ROLE)
      {
          dividendRate = newAmount;
      } 
      
      function setTokenSellDiscount(uint newAmount)
          public 
          onlyRole(ADMIN_ROLE)
      {
          tokenSellDiscount = newAmount;
      } 
      

      function withdraw()
          {
               

              address _customerAddress = msg.sender;
              uint256 _dividends = myDividends(false);

              payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

               
              _dividends += referralBalance_[_customerAddress];
              referralBalance_[_customerAddress] = 0;

              msg.sender.transfer(_dividends);

              onWithdraw(_customerAddress, _dividends);
          }

      function myDividends(bool _includeReferralBonus) 
          public 
          view 
          returns(uint256)
            {
                address _customerAddress = msg.sender;
                
                return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
            }


     
    function dividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
        {
            return (uint256) ((int256)(profitPerShare_ * balanceOf(_customerAddress)) - payoutsTo_[_customerAddress]) / magnitude;
        }
    
    function profitShare() 
        public 
        view 
        returns(uint256)
        {
            return profitPerShare_;
        }

    function payouts() 
        public 
        view 
        returns(int256)
        {
            return payoutsTo_[msg.sender];
        }

    function getTotalDivs() 
      public
      view
      returns(uint256)
      {
          return (profitPerShare_ * totalSupply);
      }


      function tokenData() 
           
          public 
          view 
          returns(uint256, uint256, uint256, uint256, uint256, uint256)
      {
          return(address(this).balance, balanceOf(msg.sender), totalSupply, myDividends(true), tokenSellDiscount, goldPrice);
      }


   
  function isOwner(address _address) public view returns (bool) {
    return owner == _address;
  }

   
  function getTransfers() public view returns (address[]) {
    return transfers;
  }

   
  function isAdmin(address _address) public view returns (bool) {
    return hasRole(_address, ADMIN_ROLE);
  }

   
  function setAdmin(address _newAdmin) public onlyOwner {
    return addRole(_newAdmin, ADMIN_ROLE);
  }

   
  function removeAdmin(address _oldAdmin) public onlyOwner {
    return removeRole(_oldAdmin, ADMIN_ROLE);
  }

   
  function setTransferable(bool _toState) public onlyRole(ADMIN_ROLE) {
    require(isTransferable != _toState, "to init a transfer toggle, the toState must change");
    toggleTransferablePending = true;
    transferToggleRequester = msg.sender;
  }

   
  function approveTransferableToggle() public onlyRole(ADMIN_ROLE) {
    require(toggleTransferablePending == true, "transfer toggle not in pending state");
    require(transferToggleRequester != msg.sender, "the requester cannot approve the transfer toggle");
    isTransferable = !isTransferable;
    toggleTransferablePending = false;
    transferToggleRequester = address(0);
  }

   
  function _transfer(address _to, address _from, uint256 _value) private returns (bool) {
    require(_value <= balances[_from], "the balance in the from address is smaller than the tx value");

     
     

  
    if(myDividends(true) > 0) withdraw();
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);

      
    payoutsTo_[_from] -= (int256) (profitPerShare_ * _value);
    payoutsTo_[_to] += (int256) (profitPerShare_ * _value);
        
     
     

    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0), "cannot transfer to the zero address");

     
    if (_to != owner && msg.sender != crowdsale) {
      require(isTransferable == true, "GGT is not yet transferable");
    }

     
    require(msg.sender != owner, "the owner of the GGT contract cannot transfer");

    return _transfer(_to, msg.sender, _value);
  }




   function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }
 
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }


   
  function adminTransfer(address _to, uint256 _quantity) public onlyRole(ADMIN_ROLE) {
    address newTransfer = new MultiSigTransfer(_quantity, _to, msg.sender);
    transfers.push(newTransfer);
  }

   
  function approveTransfer(address _approvedTransfer) public onlyRole(ADMIN_ROLE) returns (bool) {
    MultiSigTransfer transferToApprove = MultiSigTransfer(_approvedTransfer);

    uint256 transferQuantity = transferToApprove.quantity();
    address deliveryAddress = transferToApprove.targetAddress();
    address requesterAddress = transferToApprove.requesterAddress();

    require(msg.sender != requesterAddress, "a requester cannot approve an admin transfer");

    transferToApprove.approveTransfer();
    return _transfer(deliveryAddress, owner, transferQuantity);
  }

   
  function denyTransfer(address _approvedTransfer) public onlyRole(ADMIN_ROLE) returns (bool) {
    MultiSigTransfer transferToApprove = MultiSigTransfer(_approvedTransfer);
    transferToApprove.denyTransfer();
  }

  address public crowdsale = address(0);

   
  function setCrowdsaleAddress(address _crowdsaleAddress) public onlyRole(ADMIN_ROLE) {
    crowdsale = _crowdsaleAddress;
  }
}