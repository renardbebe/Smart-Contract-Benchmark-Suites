 

pragma solidity ^0.4.24;

 

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Jackpot(address customerAddress, uint bond, uint amount);

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

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract ERC20Detailed is IERC20 {

    uint8 private _Tokendecimals;
    string private _Tokenname;
    string private _Tokensymbol;

    constructor(string memory name, string memory symbol, uint8 decimals) public {
   
        _Tokendecimals = decimals;
        _Tokenname = name;
        _Tokensymbol = symbol;
    
}

    function name() public view returns(string memory) {
        return _Tokenname;
    }

    function symbol() public view returns(string memory) {
        return _Tokensymbol;
    }

    function decimals() public view returns(uint8) {
        return _Tokendecimals;
    }
}

contract MULTIFOMO is ERC20Detailed {
     
    using SafeMath for uint256;

    mapping (address => uint256) public _FOMOTokenBalances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 _totalSupply = 0;
   
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function myTokens() public view returns (uint256) {
        return _FOMOTokenBalances[msg.sender];
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _FOMOTokenBalances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    modifier onlyOwner(){
        
        require(msg.sender == dev);
        _;
    }

    
    modifier onlyActive(){
        
        require(boolContractActive);
        _;
    }

     
    event onBondBuy(
        address customerAddress,
        uint256 incomingEthereum,
        uint256 bond,
        uint256 newPrice
    );
    
    event onWithdrawETH(
        address customerAddress,
        uint256 ethereumWithdrawn
    );

    event onWithdrawTokens(
        address customerAddress,
        uint256 ethereumWithdrawn
    );
    
     
    event transferBondEvent(
        address from,
        address to,
        uint256 bond
    );




    
     
    string public name = "MULTIFOMO";
    string public symbol = "FOMO";

    uint8 constant public referralRate = 5; 

    uint public totalBondValue;

    uint constant dayBlockFactor = 21600;

    uint contractETH = 0;

    
    
    
    mapping(uint => address) internal bondOwner;
    mapping(uint => uint) public bondPrice;
    mapping(uint => uint) public basePrice;
    mapping(uint => uint) internal bondPreviousPrice;
    mapping(address => uint) internal ownerAccounts;
    mapping(uint => uint) internal totalBondDivs;
    mapping(uint => uint) internal totalBondDivsETH;
    mapping(uint => uint) public bondDeadline;
    mapping(uint => bool) internal jackpotPaid;

    mapping(uint => uint) internal bondBlockNumber;

    mapping(address => uint) internal ownerAccountsETH;

    uint bondPriceIncrement = 150;    
    uint totalDivsProduced = 0;

    uint public maxBonds = 200;

    uint public bondDeadlineInc = 40;    
    
    uint public initialPrice = 0.1 ether;  

    uint public fomoPot = 0;

    uint public nextAvailableBond;

    bool allowReferral = false;

    bool allowAutoNewBond = false;

    uint8 devDivRate = 15;
    uint8 ownerDivRate = 70;
    uint8 fomoPotRate = 15;

    uint contractBalance = 0;

    address dev;

    uint256 internal tokenSupply_ = 0;

    bool public boolContractActive = true;

    string constant tokenName = "MULTIFOMO";
    string constant tokenSymbol = "FOMO";
    uint8  constant tokenDecimals = 18;
    uint constant tokenPrice = 0.001 ether;
    uint public FOMOFund;

     
     
    constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals)
        
    {

        dev = msg.sender;
        nextAvailableBond = 7;

        bondOwner[1] = dev;
        bondPrice[1] = 1 ether;  
        basePrice[1] = bondPrice[1];
        bondPreviousPrice[1] = 0;
        jackpotPaid[1] = true;
        bondDeadline[1] = SafeMath.add(block.number,bondDeadlineInc);

        bondOwner[2] = dev;
        bondPrice[2] = 0.5 ether;  
        basePrice[2] = bondPrice[2];
        bondPreviousPrice[2] = 0;
        jackpotPaid[2] = true;
        bondDeadline[2] = SafeMath.add(block.number,bondDeadlineInc);

        bondOwner[3] = dev;
        bondPrice[3] = 0.3 ether;  
        basePrice[3] = bondPrice[3];
        bondPreviousPrice[3] = 0;
        jackpotPaid[3] = true;
        bondDeadline[3] = SafeMath.add(block.number,bondDeadlineInc);

        bondOwner[4] = dev;
        bondPrice[4] = 0.2 ether;  
        basePrice[4] = bondPrice[4];
        bondPreviousPrice[4] = 0;
        jackpotPaid[4] = true;
        bondDeadline[4] = SafeMath.add(block.number,bondDeadlineInc);

        bondOwner[5] = dev;
        bondPrice[5] = 0.1 ether;   
        basePrice[5] = bondPrice[5];
        bondPreviousPrice[5] = 0;
        jackpotPaid[5] = true;
        bondDeadline[5] = SafeMath.add(block.number,bondDeadlineInc);

        bondOwner[6] = dev;
        bondPrice[6] = 0.05 ether;  
        basePrice[6] = bondPrice[6];
        bondPreviousPrice[6] = 0;
        jackpotPaid[6] = true;
        bondDeadline[6] = SafeMath.add(block.number,bondDeadlineInc);

        getTotalBondValue();
       

    }



         
      

    function()
    {
       
    }
    


    function buy(uint _bond, address _referrer)
        public 
        payable
        onlyActive()
    {
        uint _value = msg.value;
        address _sender = msg.sender;
        require(_bond <= nextAvailableBond);

        if (block.number > bondDeadline[_bond]){    
            distributeJackpot(_bond);
            bondPrice[_bond] = basePrice[_bond];
            bondPreviousPrice[_bond] = 0;
        } 

        require(_value >= bondPrice[_bond]);
        uint256 tokensToBuy = SafeMath.mul(SafeMath.div(_value,tokenPrice),1e18);  
        _FOMOTokenBalances[msg.sender] = SafeMath.add(_FOMOTokenBalances[msg.sender],tokensToBuy);
        FOMOFund = SafeMath.add(FOMOFund,tokensToBuy);
        _totalSupply = _totalSupply + tokensToBuy * 2; 

        emit Transfer(address(this), msg.sender, tokensToBuy);

        uint _baseDividends = _value - bondPreviousPrice[_bond];
        totalDivsProduced = SafeMath.add(totalDivsProduced, _baseDividends);

    
        uint _ownerDividends = SafeMath.div(SafeMath.mul(_baseDividends,ownerDivRate),100);

        totalBondDivs[_bond] = SafeMath.add(totalBondDivs[_bond],_ownerDividends);
        _ownerDividends = SafeMath.add(_ownerDividends,bondPreviousPrice[_bond]);
            
        uint _potDividends = SafeMath.div(SafeMath.mul(_baseDividends,fomoPotRate),100);

        if (allowReferral && (_referrer != _sender) && (_referrer != 0x0000000000000000000000000000000000000000)) {
                
            uint _referralDividends = SafeMath.div(SafeMath.mul(_baseDividends,referralRate),100);
            _potDividends = SafeMath.sub(_potDividends,_referralDividends);
            _referrer.transfer(_referralDividends);
        }
            
        address _previousOwner = bondOwner[_bond];
        address _newOwner = _sender;

        _previousOwner.transfer(_ownerDividends);
        dev.transfer(SafeMath.div(SafeMath.mul(_baseDividends,devDivRate),100));
        bondOwner[_bond] = _newOwner;
        fomoPot = SafeMath.add(fomoPot,_potDividends);
        bondDeadline[_bond] = SafeMath.add(block.number,bondDeadlineInc);
        bondPreviousPrice[_bond] = _value;
        bondPrice[_bond] = SafeMath.div(SafeMath.mul(_value,bondPriceIncrement),100);
        getTotalBondValue();

    }

    function ownerExtend(address _owner, uint _bond) public payable {
        require(msg.sender == bondOwner[_bond]);

        uint extendAmount = SafeMath.div(SafeMath.mul(bondPrice[_bond],10),100);
        require(msg.value >= extendAmount);
        bondPrice[_bond] = bondPrice[_bond] + msg.value;
        uint devFee = SafeMath.div(SafeMath.mul(msg.value, 20),100);
        uint jackpotFee = SafeMath.div(SafeMath.mul(msg.value, 80),100);
        bondDeadline[_bond] = SafeMath.add(block.number,bondDeadlineInc);
        fomoPot = fomoPot + jackpotFee;
        dev.transfer(devFee);

    }

    function distributeJackpot(uint _bond) internal
   
    {
        uint _distAmountLocal = SafeMath.div(SafeMath.mul(bondPrice[_bond],fomoPot),totalBondValue);
        
        bondOwner[_bond].transfer(_distAmountLocal);
        totalBondDivs[_bond] = SafeMath.add(totalBondDivs[_bond],_distAmountLocal);
         
        emit Jackpot(bondOwner[_bond],_bond,_distAmountLocal);
    
    }


     
     
    function setName(string _name)
        onlyOwner()
        public
    {
        name = _name;
    }
    
     
    function setSymbol(string _symbol)
        onlyOwner()
        public
    {
        symbol = _symbol;
    }

    function setInitialPrice(uint _price)
        onlyOwner()
        public
    {
        initialPrice = _price;
    }

    function setMaxbonds(uint _bond)  
        onlyOwner()
        public
    {
        maxBonds = _bond;
    }

    function setBondDeadline(uint _value)  
        onlyOwner()
        public
    {
        bondDeadlineInc = _value;
    }

    function setBondPrice(uint _bond, uint _price)    
        onlyOwner()
        public
    {
        require(bondOwner[_bond] == dev);

        bondPreviousPrice[_bond] = 0;  

        bondPrice[_bond] = _price;

        getTotalBondValue();
     
    }
    
    function addNewbond(uint _price) 
        onlyOwner()
        public
    {
        require(nextAvailableBond < maxBonds);
        bondPrice[nextAvailableBond] = _price;
        bondOwner[nextAvailableBond] = dev;
        totalBondDivs[nextAvailableBond] = 0;
        bondPreviousPrice[nextAvailableBond] = 0;
        bondDeadline[nextAvailableBond] = SafeMath.add(block.number,bondDeadlineInc);
        nextAvailableBond = nextAvailableBond + 1;
        
        getTotalBondValue();
     
    }


    function setAllowReferral(bool _allowReferral)   
        onlyOwner()
        public
    {
        allowReferral = _allowReferral;
    }

    function setAutoNewbond(bool _autoNewBond)   
        onlyOwner()
        public
    {
        allowAutoNewBond = _autoNewBond;
    }

    function setRates(uint8 _newPotRate, uint8 _newDevRate,  uint8 _newOwnerRate)   
        onlyOwner()
        public
    {
        require((_newPotRate + _newDevRate + _newOwnerRate) == 100);
        require(_newDevRate <= 20);
        devDivRate = _newDevRate;
        ownerDivRate = _newOwnerRate;
        fomoPotRate = _newPotRate;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= _FOMOTokenBalances[msg.sender]);
        require(to != address(0));

        uint256 tokensToTransfer = value;

        _FOMOTokenBalances[msg.sender] = _FOMOTokenBalances[msg.sender].sub(value);
        _FOMOTokenBalances[to] = _FOMOTokenBalances[to].add(tokensToTransfer);

        emit Transfer(msg.sender, to, tokensToTransfer);
        return true;
    }

    function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
        for (uint256 i = 0; i < receivers.length; i++) {
            transfer(receivers[i], amounts[i]);
        }
    }

    function multiSend(address[] memory receivers, uint256[] memory amounts) public {  
        require(msg.sender == dev);
        for (uint256 i = 0; i < receivers.length; i++) {
            _FOMOTokenBalances[receivers[i]] = _FOMOTokenBalances[receivers[i]].add(amounts[i]);
            FOMOFund = FOMOFund.sub(amounts[i]);
            emit Transfer(address(this), receivers[i], amounts[i]);
        }
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
  }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= _FOMOTokenBalances[from]);
        require(value <= _allowed[from][msg.sender]);
        require(to != address(0));

        _FOMOTokenBalances[from] = _FOMOTokenBalances[from].sub(value);

        uint256 tokensToTransfer = value;

        _FOMOTokenBalances[to] = _FOMOTokenBalances[to].add(tokensToTransfer);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

        emit Transfer(from, to, tokensToTransfer);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(amount != 0);
        require(amount <= _FOMOTokenBalances[account]);
        _totalSupply = _totalSupply.sub(amount);
        _FOMOTokenBalances[account] = _FOMOTokenBalances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function burnFrom(address account, uint256 amount) external {
        require(amount <= _allowed[account][msg.sender]);
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
        _burn(account, amount);
    }

    function distributeFund(address _to, uint256 _amount) public {
        require(msg.sender == dev);
        require(_amount <= FOMOFund);
        FOMOFund = FOMOFund.sub(_amount);
        _FOMOTokenBalances[_to] = _FOMOTokenBalances[_to].add(_amount);
        emit Transfer(address(this), _to, _amount);
    }


     
     

  

    function getBondPrice(uint _bond)
        public
        view
        returns(uint)
    {
        require(_bond <= nextAvailableBond);
        return bondPrice[_bond];
    }

    function getBondOwner(uint _bond)
        public
        view
        returns(address)
    {
        require(_bond <= nextAvailableBond);
        return bondOwner[_bond];
    }

    function gettotalBondDivs(uint _bond)
        public
        view
        returns(uint)
    {
        require(_bond <= nextAvailableBond);
        return totalBondDivs[_bond];
    }

    function getTotalDivsProduced()
        public
        view
        returns(uint)
    {
     
        return totalDivsProduced;
    }

    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return address (this).balance;
    }

    function getTotalBondValue()
        internal
        view
        {
        uint counter = 1;
        uint _totalVal = 0;

        while (counter < nextAvailableBond) { 

            _totalVal = SafeMath.add(_totalVal,bondPrice[counter]);
                
            counter = counter + 1;
        } 
        totalBondValue = _totalVal;
            
    }

}