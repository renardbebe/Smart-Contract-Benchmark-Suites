 

pragma solidity ^0.4.21;

 
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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




contract ERC20 {

    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract MultiOwnable {

    mapping (address => bool) public isOwner;
    address[] public ownerHistory;

    event OwnerAddedEvent(address indexed _newOwner);
    event OwnerRemovedEvent(address indexed _oldOwner);

    constructor() {
         
        address owner = msg.sender;
        ownerHistory.push(owner);
        isOwner[owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender]);
        _;
    }

    function ownerHistoryCount() public view returns (uint) {
        return ownerHistory.length;
    }

     
    function addOwner(address owner) onlyOwner public {
        require(owner != address(0));
        require(!isOwner[owner]);
        ownerHistory.push(owner);
        isOwner[owner] = true;
        emit OwnerAddedEvent(owner);
    }

     
    function removeOwner(address owner) onlyOwner public {
        require(isOwner[owner]);
        isOwner[owner] = false;
        emit OwnerRemovedEvent(owner);
    }
}









contract Pausable is MultiOwnable {

    bool public paused;

    modifier ifNotPaused {
        require(!paused);
        _;
    }

    modifier ifPaused {
        require(paused);
        _;
    }

     
    function pause() external onlyOwner ifNotPaused {
        paused = true;
    }

     
    function resume() external onlyOwner ifPaused {
        paused = false;
    }
}








contract StandardToken is ERC20 {

    using SafeMath for uint;

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowed;

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
     
     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}



contract CommonToken is StandardToken, MultiOwnable {

    string public constant name   = 'TMSY';
    string public constant symbol = 'TMSY';
    uint8 public constant decimals = 18;

    uint256 public saleLimit;    
    uint256 public teamTokens;   
    uint256 public partnersTokens;
    uint256 public advisorsTokens;
    uint256 public reservaTokens;

     
    address public teamWallet;  
    address public partnersWallet;  
    address public advisorsWallet;  
    address public reservaWallet;

    uint public unlockTeamTokensTime = now + 365 days;

     
    address public seller;  

    uint256 public tokensSold;  
    uint256 public totalSales;  

     
    bool public locked = true;
    mapping (address => bool) public walletsNotLocked;

    event SellEvent(address indexed _seller, address indexed _buyer, uint256 _value);
    event ChangeSellerEvent(address indexed _oldSeller, address indexed _newSeller);
    event Burn(address indexed _burner, uint256 _value);
    event Unlock();

    constructor (
        address _seller,
        address _teamWallet,
        address _partnersWallet,
        address _advisorsWallet,
        address _reservaWallet
    ) MultiOwnable() public {

        totalSupply    = 600000000 ether;
        saleLimit      = 390000000 ether;
        teamTokens     = 120000000 ether;
        partnersTokens =  30000000 ether;
        reservaTokens  =  30000000 ether;
        advisorsTokens =  30000000 ether;

        seller         = _seller;
        teamWallet     = _teamWallet;
        partnersWallet = _partnersWallet;
        advisorsWallet = _advisorsWallet;
        reservaWallet  = _reservaWallet;

        uint sellerTokens = totalSupply - teamTokens - partnersTokens - advisorsTokens - reservaTokens;
        balances[seller] = sellerTokens;
        emit Transfer(0x0, seller, sellerTokens);

        balances[teamWallet] = teamTokens;
        emit Transfer(0x0, teamWallet, teamTokens);

        balances[partnersWallet] = partnersTokens;
        emit Transfer(0x0, partnersWallet, partnersTokens);

        balances[reservaWallet] = reservaTokens;
        emit Transfer(0x0, reservaWallet, reservaTokens);

        balances[advisorsWallet] = advisorsTokens;
        emit Transfer(0x0, advisorsWallet, advisorsTokens);
    }

    modifier ifUnlocked(address _from, address _to) {
         
         
         
        require(walletsNotLocked[_to]);

        require(!locked);

         
         
         
         

         

         

        _;
    }

     
    function unlock() onlyOwner public {
        require(locked);
        locked = false;
        emit Unlock();
    }

    function walletLocked(address _wallet) onlyOwner public {
      walletsNotLocked[_wallet] = false;
    }

    function walletNotLocked(address _wallet) onlyOwner public {
      walletsNotLocked[_wallet] = true;
    }

     
    function changeSeller(address newSeller) onlyOwner public returns (bool) {
        require(newSeller != address(0));
        require(seller != newSeller);

         
        require(balances[newSeller] == 0);

        address oldSeller = seller;
        uint256 unsoldTokens = balances[oldSeller];
        balances[oldSeller] = 0;
        balances[newSeller] = unsoldTokens;
        emit Transfer(oldSeller, newSeller, unsoldTokens);

        seller = newSeller;
        emit ChangeSellerEvent(oldSeller, newSeller);
        return true;
    }

     
    function sellNoDecimals(address _to, uint256 _value) public returns (bool) {
        return sell(_to, _value * 1e18);
    }

    function sell(address _to, uint256 _value)  public returns (bool) {
         
         
         
        require(msg.sender == seller, "User not authorized");

        require(_to != address(0));
        require(_value > 0);

        require(_value <= balances[seller]);

        balances[seller] = balances[seller].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(seller, _to, _value);

        totalSales++;
        tokensSold = tokensSold.add(_value);
        emit SellEvent(seller, _to, _value);
        return true;
    }

     
    function transfer(address _to, uint256 _value) ifUnlocked(msg.sender, _to) public returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) ifUnlocked(_from, _to) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function burn(uint256 _value) public returns (bool) {
        require(_value > 0, 'Value is zero');

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Transfer(msg.sender, 0x0, _value);
        emit Burn(msg.sender, _value);
        return true;
    }
}



contract CommonTokensale is MultiOwnable, Pausable {

    using SafeMath for uint;

    address public beneficiary;
    uint public refundDeadlineTime;

     
    uint public balance;
    uint public balanceComision;
    uint public balanceComisionHold;
    uint public balanceComisionDone;

     
    CommonToken public token;

    uint public minPaymentUSD = 250;

    uint public minCapWei;
    uint public maxCapWei;

    uint public minCapUSD;
    uint public maxCapUSD;

    uint public startTime;
    uint public endTime;

     

    uint public totalTokensSold;   
    uint public totalWeiReceived;  
    uint public totalUSDReceived;  

     
    mapping (address => uint256) public buyerToSentWei;
    mapping (address => uint256) public sponsorToComisionDone;
    mapping (address => uint256) public sponsorToComision;
    mapping (address => uint256) public sponsorToComisionHold;
    mapping (address => uint256) public sponsorToComisionFromInversor;
    mapping (address => bool) public kicInversor;
    mapping (address => bool) public validateKYC;
    mapping (address => bool) public comisionInTokens;

    address[] public sponsorToComisionList;

     

    event ReceiveEthEvent(address indexed _buyer, uint256 _amountWei);
    event NewInverstEvent(address indexed _child, address indexed _sponsor);
    event ComisionEvent(address indexed _sponsor, address indexed _child, uint256 _value, uint256 _comision);
    event ComisionPayEvent(address indexed _sponsor, uint256 _value, uint256 _comision);
    event ComisionInversorInTokensEvent(address indexed _sponsor, bool status);
    event ChangeEndTimeEvent(address _sender, uint _date);
    event verifyKycEvent(address _sender, uint _date, bool _status);
    event payComisionSponsorTMSY(address _sponsor, uint _date, uint _value);
    event payComisionSponsorETH(address _sponsor, uint _date, uint _value);
    event withdrawEvent(address _sender, address _to, uint value, uint _date);
     
    uint public rateUSDETH;

    bool public isSoftCapComplete = false;

     
    mapping(address => bool) public inversors;
    address[] public inversorsList;

     
    mapping(address => address) public inversorToSponsor;

    constructor (
        address _token,
        address _beneficiary,
        uint _startTime,
        uint _endTime
    ) MultiOwnable() public {

        require(_token != address(0));
        token = CommonToken(_token);

        beneficiary = _beneficiary;

        startTime = _startTime;
        endTime   = _endTime;


        minCapUSD = 400000;
        maxCapUSD = 4000000;
    }

    function setRatio(uint _rate) onlyOwner public returns (bool) {
      rateUSDETH = _rate;
      return true;
    }

     
     

    function burn(uint _value) onlyOwner public returns (bool) {
      return token.burn(_value);
    }

    function newInversor(address _newInversor, address _sponsor) onlyOwner public returns (bool) {
      inversors[_newInversor] = true;
      inversorsList.push(_newInversor);
      inversorToSponsor[_newInversor] = _sponsor;
      emit NewInverstEvent(_newInversor,_sponsor);
      return inversors[_newInversor];
    }
    function setComisionInvesorInTokens(address _inversor, bool _inTokens) onlyOwner public returns (bool) {
      comisionInTokens[_inversor] = _inTokens;
      emit ComisionInversorInTokensEvent(_inversor, _inTokens);
      return true;
    }
    function setComisionInTokens() public returns (bool) {
      comisionInTokens[msg.sender] = true;
      emit ComisionInversorInTokensEvent(msg.sender, true);
      return true;
    }
    function setComisionInETH() public returns (bool) {
      comisionInTokens[msg.sender] = false;
      emit ComisionInversorInTokensEvent(msg.sender, false);

      return true;
    }
    function inversorIsKyc(address who) public returns (bool) {
      return validateKYC[who];
    }
    function unVerifyKyc(address _inversor) onlyOwner public returns (bool) {
      require(!isSoftCapComplete);

      validateKYC[_inversor] = false;

      address sponsor = inversorToSponsor[_inversor];
      uint balanceHold = sponsorToComisionFromInversor[_inversor];

       
      balanceComision = balanceComision.sub(balanceHold);
      balanceComisionHold = balanceComisionHold.add(balanceHold);

       
      sponsorToComision[sponsor] = sponsorToComision[sponsor].sub(balanceHold);
      sponsorToComisionHold[sponsor] = sponsorToComisionHold[sponsor].add(balanceHold);

       
     
      emit verifyKycEvent(_inversor, now, false);
    }
    function verifyKyc(address _inversor) onlyOwner public returns (bool) {
      validateKYC[_inversor] = true;

      address sponsor = inversorToSponsor[_inversor];
      uint balanceHold = sponsorToComisionFromInversor[_inversor];

       
      balanceComision = balanceComision.add(balanceHold);
      balanceComisionHold = balanceComisionHold.sub(balanceHold);

       
      sponsorToComision[sponsor] = sponsorToComision[sponsor].add(balanceHold);
      sponsorToComisionHold[sponsor] = sponsorToComisionHold[sponsor].sub(balanceHold);

       
       
      emit verifyKycEvent(_inversor, now, true);
       
       
      return true;
    }
    function buyerToSentWeiOf(address who) public view returns (uint256) {
      return buyerToSentWei[who];
    }
    function balanceOf(address who) public view returns (uint256) {
      return token.balanceOf(who);
    }
    function balanceOfComision(address who)  public view returns (uint256) {
      return sponsorToComision[who];
    }
    function balanceOfComisionHold(address who)  public view returns (uint256) {
      return sponsorToComisionHold[who];
    }
    function balanceOfComisionDone(address who)  public view returns (uint256) {
      return sponsorToComisionDone[who];
    }

    function isInversor(address who) public view returns (bool) {
      return inversors[who];
    }
    function payComisionSponsor(address _inversor) private {
       
       
      if(comisionInTokens[_inversor]) {
        uint256 val = 0;
        uint256 valueHold = sponsorToComisionHold[_inversor];
        uint256 valueReady = sponsorToComision[_inversor];

        val = valueReady.add(valueHold);
         
        if(val > 0) {
          require(balanceComision >= valueReady);
          require(balanceComisionHold >= valueHold);
         uint256 comisionTokens = weiToTokens(val);

          sponsorToComision[_inversor] = 0;
          sponsorToComisionHold[_inversor] = 0;

          balanceComision = balanceComision.sub(valueReady);
          balanceComisionDone = balanceComisionDone.add(val);
          balanceComisionHold = balanceComisionHold.sub(valueHold);

          balance = balance.add(val);

          token.sell(_inversor, comisionTokens);
          emit payComisionSponsorTMSY(_inversor, now, val);  
        }
      } else {
        uint256 value = sponsorToComision[_inversor];

         
        if(value > 0) {
          require(balanceComision >= value);

           
           
          assert(isSoftCapComplete);

           
          assert(validateKYC[_inversor]);

          sponsorToComision[_inversor] = sponsorToComision[_inversor].sub(value);
          balanceComision = balanceComision.sub(value);
          balanceComisionDone = balanceComisionDone.add(value);

          _inversor.transfer(value);
          emit payComisionSponsorETH(_inversor, now, value);  

        }

      }
    }
    function payComision() public {
      address _inversor = msg.sender;
      payComisionSponsor(_inversor);
    }
     
     
    function isSoftCapCompleted() public view returns (bool) {
      return isSoftCapComplete;
    }
    function softCapCompleted() public {
      uint totalBalanceUSD = weiToUSD(balance.div(1e18));
      if(totalBalanceUSD >= minCapUSD) isSoftCapComplete = true;
    }

    function balanceComisionOf(address who) public view returns (uint256) {
      return sponsorToComision[who];
    }

     
    function() public payable {
         

        uint256 _amountWei = msg.value;
        address _buyer = msg.sender;
        uint valueUSD = weiToUSD(_amountWei);

         
        require(inversors[_buyer] != false);
        require(valueUSD >= minPaymentUSD);
         

        uint tokensE18SinBono = weiToTokens(msg.value);
        uint tokensE18Bono = weiToTokensBono(msg.value);
        uint tokensE18 = tokensE18SinBono.add(tokensE18Bono);

         
        require(token.sell(_buyer, tokensE18SinBono), "Falla la venta");
        if(tokensE18Bono > 0)
          assert(token.sell(_buyer, tokensE18Bono));

         
        uint256 _amountSponsor = (_amountWei * 10) / 100;
        uint256 _amountBeneficiary = (_amountWei * 90) / 100;

        totalTokensSold = totalTokensSold.add(tokensE18);
        totalWeiReceived = totalWeiReceived.add(_amountWei);
        buyerToSentWei[_buyer] = buyerToSentWei[_buyer].add(_amountWei);
        emit ReceiveEthEvent(_buyer, _amountWei);

         
        if(!isSoftCapComplete) {
          uint256 totalBalanceUSD = weiToUSD(balance);
          if(totalBalanceUSD >= minCapUSD) {
            softCapCompleted();
          }
        }
        address sponsor = inversorToSponsor[_buyer];
        sponsorToComisionList.push(sponsor);

        if(validateKYC[_buyer]) {
           
          balanceComision = balanceComision.add(_amountSponsor);
          sponsorToComision[sponsor] = sponsorToComision[sponsor].add(_amountSponsor);

        } else {
           
          balanceComisionHold = balanceComisionHold.add(_amountSponsor);
          sponsorToComisionHold[sponsor] = sponsorToComisionHold[sponsor].add(_amountSponsor);
          sponsorToComisionFromInversor[_buyer] = sponsorToComisionFromInversor[_buyer].add(_amountSponsor);
        }


        payComisionSponsor(sponsor);

         
       

        balance = balance.add(_amountBeneficiary);
    }

    function weiToUSD(uint _amountWei) public view returns (uint256) {
      uint256 ethers = _amountWei;

      uint256 valueUSD = rateUSDETH.mul(ethers);

      return valueUSD;
    }

    function weiToTokensBono(uint _amountWei) public view returns (uint256) {
      uint bono = 0;

      uint256 valueUSD = weiToUSD(_amountWei);

       
       
      if(valueUSD >= uint(500 * 1e18))   bono = 10;
      if(valueUSD >= uint(1000 * 1e18))  bono = 20;
      if(valueUSD >= uint(2500 * 1e18))  bono = 30;
      if(valueUSD >= uint(5000 * 1e18))  bono = 40;
      if(valueUSD >= uint(10000 * 1e18)) bono = 50;


      uint256 bonoUsd = valueUSD.mul(bono).div(100);
      uint256 tokens = bonoUsd.mul(tokensPerUSD());

      return tokens;
    }
     
    function weiToTokens(uint _amountWei) public view returns (uint256) {

        uint256 valueUSD = weiToUSD(_amountWei);

        uint256 tokens = valueUSD.mul(tokensPerUSD());

        return tokens;
    }

    function tokensPerUSD() public pure returns (uint256) {
        return 65;  
    }

    function canWithdraw() public view returns (bool);

    function withdraw(address _to, uint value) public returns (uint) {
        require(canWithdraw(), 'No es posible retirar');
        require(msg.sender == beneficiary, 'Sólo puede solicitar el beneficiario los fondos');
        require(balance > 0, 'Sin fondos');
        require(balance >= value, 'No hay suficientes fondos');
        require(_to.call.value(value).gas(1)(), 'No se que es');

        balance = balance.sub(value);
        emit withdrawEvent(msg.sender, _to, value,now);
      return balance;
    }

     
    function changeEndTime(uint _date) onlyOwner public returns (bool) {
       
      require(endTime < _date);
      endTime = _date;
      refundDeadlineTime = endTime + 3 * 30 days;
      emit ChangeEndTimeEvent(msg.sender,_date);
      return true;
    }
}


contract Presale is CommonTokensale {

     
     

     
    uint public totalWeiRefunded;

    event RefundEthEvent(address indexed _buyer, uint256 _amountWei);

    constructor(
        address _token,
        address _beneficiary,
        uint _startTime,
        uint _endTime
    ) CommonTokensale(
        _token,
        _beneficiary,
        _startTime,
        _endTime
    ) public {
      refundDeadlineTime = _endTime + 3 * 30 days;
    }

     
    function canWithdraw() public view returns (bool) {
        return isSoftCapComplete;
    }

     
    function canRefund() public view returns (bool) {
        return !isSoftCapComplete && endTime < now && now <= refundDeadlineTime;
    }

    function refund() public {
        require(canRefund());

        address buyer = msg.sender;
        uint amount = buyerToSentWei[buyer];
        require(amount > 0);

         
        uint newBal = balance.sub(amount);
        balance = newBal;

        emit RefundEthEvent(buyer, amount);
        buyerToSentWei[buyer] = 0;
        totalWeiRefunded = totalWeiRefunded.add(amount);
        buyer.transfer(amount);
    }
}