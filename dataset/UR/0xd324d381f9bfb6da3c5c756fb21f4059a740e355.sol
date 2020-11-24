 

pragma solidity ^0.4.24;

 
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


 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


contract BasicERC20
{
     
    string public standard = 'ERC20';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    bool public isTokenTransferable = true;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function transfer(address _to, uint256 _value) public {
        assert(isTokenTransferable);
        assert(balanceOf[msg.sender] >= _value);              
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
        emit Transfer(msg.sender, _to, _value);                    
    }

     
    function approve(address _spender, uint256 _value) public
    returns (bool success)  {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        assert(isTokenTransferable);
        if (balanceOf[_from] < _value) throw;                  
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;   
        if (_value > allowance[_from][msg.sender]) throw;    
        balanceOf[_from] -= _value;                           
        balanceOf[_to] += _value;                             
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}














contract BasicCrowdsale is Ownable
{
    using SafeMath for uint256;
    BasicERC20 token;

    address public ownerWallet;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalEtherRaised = 0;
    uint256 public minDepositAmount;
    uint256 public maxDepositAmount;

    uint256 public softCapEther;
    uint256 public hardCapEther;

    mapping(address => uint256) private deposits;

    constructor () public {

    }

    function () external payable {
        buy(msg.sender);
    }

    function getSettings () view public returns(uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _totalEtherRaised,
        uint256 _minDepositAmount,
        uint256 _maxDepositAmount,
        uint256 _tokensLeft ) {

        _startTime = startTime;
        _endTime = endTime;
        _rate = getRate();
        _totalEtherRaised = totalEtherRaised;
        _minDepositAmount = minDepositAmount;
        _maxDepositAmount = maxDepositAmount;
        _tokensLeft = tokensLeft();
    }

    function tokensLeft() view public returns (uint256)
    {
        return token.balanceOf(address(0x0));
    }

    function changeMinDepositAmount (uint256 _minDepositAmount) onlyOwner public {
        minDepositAmount = _minDepositAmount;
    }

    function changeMaxDepositAmount (uint256 _maxDepositAmount) onlyOwner public {
        maxDepositAmount = _maxDepositAmount;
    }

    function getRate() view public returns (uint256) {
        assert(false);
    }

    function getTokenAmount(uint256 weiAmount) public view returns(uint256) {
        return weiAmount.mul(getRate());
    }

    function checkCorrectPurchase() view internal {
        require(startTime < now && now < endTime);
        require(msg.value > minDepositAmount);
        require(msg.value < maxDepositAmount);
        require(totalEtherRaised + msg.value < hardCapEther);
    }

    function isCrowdsaleFinished() view public returns(bool)
    {
        return totalEtherRaised >= hardCapEther || now > endTime;
    }

    function buy(address userAddress) public payable {
        require(userAddress != address(0));
        checkCorrectPurchase();

         
        uint256 tokens = getTokenAmount(msg.value);

         
        totalEtherRaised = totalEtherRaised.add(msg.value);

        token.transferFrom(address(0x0), userAddress, tokens);

        if (totalEtherRaised >= softCapEther)
        {
            ownerWallet.transfer(this.balance);
        }
        else
        {
            deposits[userAddress] = deposits[userAddress].add(msg.value);
        }
    }

    function getRefundAmount(address userAddress) view public returns (uint256)
    {
        if (totalEtherRaised >= softCapEther) return 0;
        return deposits[userAddress];
    }

    function refund(address userAddress) public
    {
        assert(totalEtherRaised < softCapEther && now > endTime);
        uint256 amount = deposits[userAddress];
        deposits[userAddress] = 0;
        userAddress.transfer(amount);
    }
}


contract CrowdsaleCompatible is BasicERC20, Ownable
{
    BasicCrowdsale public crowdsale = BasicCrowdsale(0x0);

     
    function unfreezeTokens() public
    {
        assert(now > crowdsale.endTime());
        isTokenTransferable = true;
    }

     
    function initializeCrowdsale(address crowdsaleContractAddress, uint256 tokensAmount) onlyOwner public  {
        transfer((address)(0x0), tokensAmount);
        allowance[(address)(0x0)][crowdsaleContractAddress] = tokensAmount;
        crowdsale = BasicCrowdsale(crowdsaleContractAddress);
        isTokenTransferable = false;
        transferOwnership(0x0);  
    }
}







contract EditableToken is BasicERC20, Ownable {
    using SafeMath for uint256;

     
    function editTokenProperties(string _name, string _symbol, int256 extraSupplay) onlyOwner public {
        name = _name;
        symbol = _symbol;
        if (extraSupplay > 0)
        {
            balanceOf[owner] = balanceOf[owner].add(uint256(extraSupplay));
            totalSupply = totalSupply.add(uint256(extraSupplay));
            emit Transfer(address(0x0), owner, uint256(extraSupplay));
        }
        else if (extraSupplay < 0)
        {
            balanceOf[owner] = balanceOf[owner].sub(uint256(extraSupplay * -1));
            totalSupply = totalSupply.sub(uint256(extraSupplay * -1));
            emit Transfer(owner, address(0x0), uint256(extraSupplay * -1));
        }
    }
}







contract ThirdPartyTransferableToken is BasicERC20{
    using SafeMath for uint256;

    struct confidenceInfo {
        uint256 nonce;
        mapping (uint256 => bool) operation;
    }
    mapping (address => confidenceInfo) _confidence_transfers;

    function nonceOf(address src) view public returns (uint256) {
        return _confidence_transfers[src].nonce;
    }

    function transferByThirdParty(uint256 nonce, address where, uint256 amount, uint8 v, bytes32 r, bytes32 s) public returns (bool){
        assert(where != address(this));
        assert(where != address(0x0));

        bytes32 hash = sha256(this, nonce, where, amount);
        address src = ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash),v,r,s);
        assert(balanceOf[src] >= amount);
        assert(nonce == _confidence_transfers[src].nonce+1);

        assert(_confidence_transfers[src].operation[uint256(hash)]==false);

        balanceOf[src] = balanceOf[src].sub(amount);
        balanceOf[where] = balanceOf[where].add(amount);
        _confidence_transfers[src].nonce += 1;
        _confidence_transfers[src].operation[uint256(hash)] = true;

        emit Transfer(src, where, amount);

        return true;
    }
}



contract ERC20Token is CrowdsaleCompatible, EditableToken, ThirdPartyTransferableToken {
    using SafeMath for uint256;

     
    constructor() public
    {
        balanceOf[0x0fCDC65C29a538f58DB5186533d93BcA7A359a33] = uint256(3300000000) * 10**18;
        emit Transfer(address(0x0), 0x0fCDC65C29a538f58DB5186533d93BcA7A359a33, balanceOf[0x0fCDC65C29a538f58DB5186533d93BcA7A359a33]);

        transferOwnership(0x0fCDC65C29a538f58DB5186533d93BcA7A359a33);

        totalSupply = 3300000000 * 10**18;                   
        name = 'ITM Transmission';                                
        symbol = 'ITM';                                           
        decimals = 18;                                            
    }

     
    function () public {
        assert(false);      
    }
}