 

pragma solidity ^0.4.24;

 
 
 
 
 
 

 
 

 
 
 
 

 

 
 
 
 
 

 
 
 
 
 

library SafeMath {
    
     
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

     
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

     
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
     
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
     
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
     
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }   
}

contract ERC223ReceivingContract { 
 
    function tokenFallback(address _from, uint _value, bytes _data)public;
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract ChickenPark is Owned{

    using SafeMath for *;

    modifier notContract() {
        require (msg.sender == tx.origin);
        _;
    }
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint tokens
    );

    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint tokens
    );

    event CKNPrice(
        address indexed who,
        uint prePrice,
        uint afterPrice,
        uint ethValue,
        uint token,
        uint timestamp,
        string action
    );
    
    event Withdraw(
        address indexed who,
        uint dividents
    );

     
    uint8 constant public                decimals              = 18;
    uint constant internal               tokenPriceInitial_    = 0.00001 ether;
    uint constant internal               magnitude             = 2**64;

     
    string public                        name               = "Chicken Park Coin";
    string public                        symbol             = "CKN";

     

     
    mapping(address => uint) internal    balances;
    mapping(address => mapping (address => uint))public allowed;

     
    mapping(address => uint)    public referralBalance_;
    mapping(address => int256)  public payoutsTo_;
    uint256 public profitPerShare_ = 0;
    
     
    uint internal tokenSupply = 0;

     
    mapping(address => bool)  public gameAddress;
    address public marketAddress;

     

    constructor() public {

    }

    function totalSupply() public view returns (uint) {
        return tokenSupply.sub(balances[address(0)]);
    }

     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
    function referralBalanceOf(address tokenOwner) public view returns(uint){
        return referralBalance_[tokenOwner];
    }

    function setGameAddrt(address addr_, bool status_) public onlyOwner{
        gameAddress[addr_] = status_;
    }
    
    function setMarketAddr(address addr_) public onlyOwner{
        marketAddress = addr_;
    }

     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        require(balances[msg.sender] >= tokens);

        payoutsTo_[msg.sender] = payoutsTo_[msg.sender] - int(tokens.mul(profitPerShare_)/1e18);
        payoutsTo_[to] = payoutsTo_[to] + int(tokens.mul(profitPerShare_)/1e18);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);

        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(tokens <= balances[from] &&  tokens <= allowed[from][msg.sender]);

        payoutsTo_[from] = payoutsTo_[from] - int(tokens.mul(profitPerShare_)/1e18);
        payoutsTo_[to] = payoutsTo_[to] + int(tokens.mul(profitPerShare_)/1e18);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

     
     
     
    function buyChickenParkCoin(address referedAddress) notContract() public payable{
        uint fee = msg.value.mul(2)/100;
        owner.transfer(fee/2);

        marketAddress.transfer(fee/2);

        uint realBuy = msg.value.sub(fee).mul((1e20).sub(calculateDivi()))/1e20;
        uint divMoney = msg.value.sub(realBuy).sub(fee);

        if(referedAddress != msg.sender && referedAddress != address(0)){
            uint referralMoney = divMoney/10;
            referralBalance_[referedAddress] = referralBalance_[referedAddress].add(referralMoney);
            divMoney = divMoney.sub(referralMoney);
        }

        uint tokenAdd = getBuy(realBuy);
        uint price1 = getCKNPriceNow();

        tokenSupply = tokenSupply.add(tokenAdd);

        payoutsTo_[msg.sender] += (int256)(profitPerShare_.mul(tokenAdd)/1e18);
        profitPerShare_ = profitPerShare_.add(divMoney.mul(1e18)/totalSupply());
        balances[msg.sender] = balances[msg.sender].add(tokenAdd);

        uint price2 = getCKNPriceNow();
        emit Transfer(address(0x0), msg.sender, tokenAdd);
        emit CKNPrice(msg.sender,price1,price2,msg.value,tokenAdd,now,"BUY");
    } 

     
     
     
    function sellChickenParkCoin(uint tokenAnount) notContract() public {
        uint tokenSub = tokenAnount;
        uint sellEther = getSell(tokenSub);
        uint price1 = getCKNPriceNow();

        payoutsTo_[msg.sender] = payoutsTo_[msg.sender] - int(tokenSub.mul(profitPerShare_)/1e18);
        tokenSupply = tokenSupply.sub(tokenSub);

        balances[msg.sender] = balances[msg.sender].sub(tokenSub);
        uint diviTo = sellEther.mul(calculateDivi())/1e20;

        if(totalSupply()>0){
            profitPerShare_ = profitPerShare_.add(diviTo.mul(1e18)/totalSupply());
        }else{
            owner.transfer(diviTo); 
        }

        owner.transfer(sellEther.mul(1)/100);
        marketAddress.transfer(sellEther.mul(1)/100);

        msg.sender.transfer((sellEther.mul(98)/(100)).sub(diviTo));

        uint price2 = getCKNPriceNow();
        emit Transfer(msg.sender, address(0x0), tokenSub);
        emit CKNPrice(msg.sender,price1,price2,sellEther,tokenSub,now,"SELL");
    }

     
     
     
    function withdraw() public {
        require(msg.sender == tx.origin || msg.sender == marketAddress || gameAddress[msg.sender]);
        require(myDividends(true)>0);

        uint dividents_ = uint(getDividents()).add(referralBalance_[msg.sender]);
        payoutsTo_[msg.sender] = payoutsTo_[msg.sender] + int(getDividents());
        referralBalance_[msg.sender] = 0;

        msg.sender.transfer(dividents_);
        emit Withdraw(msg.sender, dividents_);
    }
    
     
     
     
    function transferTo (address _from, address _to, uint _amountOfTokens, bytes _data) public {
        if (_from != msg.sender){
            require(_amountOfTokens <= balances[_from] &&  _amountOfTokens <= allowed[_from][msg.sender]);
        }
        else{
            require(_amountOfTokens <= balances[_from]);
        }

        transferFromInternal(_from, _to, _amountOfTokens, _data);
    }

    function transferFromInternal(address _from, address _toAddress, uint _amountOfTokens, bytes _data) internal
    {
        require(_toAddress != address(0x0));
        address _customerAddress     = _from;
        
        if (_customerAddress != msg.sender){
         
         
            allowed[_customerAddress][msg.sender] = allowed[_customerAddress][msg.sender].sub(_amountOfTokens);
        }

         
        balances[_customerAddress]    = balances[_customerAddress].sub(_amountOfTokens);
        balances[_toAddress]          = balances[_toAddress].add(_amountOfTokens);

         
        payoutsTo_[_customerAddress] -= (int256)(profitPerShare_.mul(_amountOfTokens)/1e18);
        payoutsTo_[_toAddress]       +=  (int256)(profitPerShare_.mul(_amountOfTokens)/1e18);

        uint length;

        assembly {
            length := extcodesize(_toAddress)
        }

        if (length > 0){
         
         
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_toAddress);
            receiver.tokenFallback(_from, _amountOfTokens, _data);
        }

         
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
    }

    function getCKNPriceNow() public view returns(uint){
        return (tokenPriceInitial_.mul(1e18+totalSupply()/100000000))/(1e18);
    }

    function getBuy(uint eth) public view returns(uint){
        return ((((1e36).add(totalSupply().sq()/1e16).add(totalSupply().mul(2).mul(1e10)).add(eth.mul(1e28).mul(2)/tokenPriceInitial_)).sqrt()).sub(1e18).sub(totalSupply()/1e8)).mul(1e8);
    }

    function calculateDivi()public view returns(uint){
        if(totalSupply() < 4e26){
            uint diviRate = (20e18).sub(totalSupply().mul(5)/1e8);
            return diviRate;
        } else {
            return 0;
        }
    }

    function getSell(uint token) public view returns(uint){
        return tokenPriceInitial_.mul((1e18).add((totalSupply().sub(token/2))/100000000)).mul(token)/(1e36);
    }

    function myDividends(bool _includeReferralBonus) public view returns(uint256)
    {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? getDividents().add(referralBalance_[_customerAddress]) : getDividents() ;
    }

    function getDividents() public view returns(uint){
        require(int((balances[msg.sender].mul(profitPerShare_)/1e18))-(payoutsTo_[msg.sender])>=0);
        return uint(int((balances[msg.sender].mul(profitPerShare_)/1e18))-(payoutsTo_[msg.sender]));
    }
}