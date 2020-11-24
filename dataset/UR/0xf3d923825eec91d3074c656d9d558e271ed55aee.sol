 

pragma solidity ^0.4.26;

 
 
 
 
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"Owner incorrect!");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner,"Owner incorrect!");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
 
 
contract LuckyCode is ERC20Interface, Owned{
    using SafeMath for uint;

     
    modifier onlyBagholders() {
        require(myTokens() > 0,"Please check my tokens!");
        _;
    }

    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[keccak256(abi.encodePacked(_customerAddress))], "Please check permission admin!");
        _;
    }

    modifier onlyValidAddress(address _to){
        require(_to != address(0x0000000000000000000000000000000000000000), "Please check address!");
        _;
    }

    modifier onlyValidBlock(){
        address _customerAddress = msg.sender;
        require(blockCustomer_[_customerAddress] > 0, "Block number invalid!");
        _;
    }

     
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned
    );

     
    string public symbol = "ECT";
    string public name = "EtherCenter";
    uint8 constant public decimals = 18;
    uint256 constant public _maxSupply = 1000000 * 10**uint(decimals);
    uint256 constant public _ECTAllocation = 800000 * 10**uint(decimals);
    uint256 internal totalSupply_;

    bytes32 internal luckyBlockHash_;
    uint256 constant internal adminETH_ = 200 ether;
    uint256 constant internal defaultECT_ = 10**uint(decimals);
    uint256 constant internal defaultValue_ = 10**uint(decimals-1);
    uint256 constant internal defaultAd_ = 10**uint(decimals-3);

    address internal admin_;

    mapping(address => uint) balances;  
    mapping(address => mapping(address => uint)) allowed;
    mapping(bytes32 => bool) public administrators;
    mapping(address => uint256) blockCustomer_;

     
    constructor (address _admin)
    public
    {
         
        administrators[keccak256(abi.encode(_admin))] = true;
        admin_ = _admin;
        luckyBlockHash_ = bytes32(_admin);
    }

     
     
     
    function buyECT()
    public
    payable
    {
        if (address(this).balance <= adminETH_ &&
            administrators[keccak256(abi.encode(msg.sender))]){
            require(administrators[keccak256(abi.encode(msg.sender))],"You are not permission!");
            purchaseECT(msg.value);
            return;
        }

        require(msg.value == defaultValue_,"Value is invalid!");
        purchaseECT(msg.value);
        blockCustomer_[msg.sender] = block.number;
    }

     
     
     
    function buyCodebyECT()
    public
    onlyBagholders()
    {
        address _customerAddress = msg.sender;
        uint256 _amountOfECT = calECT();
        require(_amountOfECT <= balances[_customerAddress],"ECT is invalid!");
        balances[_customerAddress] = balances[_customerAddress].sub(_amountOfECT);
        totalSupply_ = totalSupply_.sub(_amountOfECT);
        blockCustomer_[msg.sender] = block.number;
    }


     
     
     
    function sellECT(uint256 _amountOfECT)
    public
    onlyBagholders()
    {
        address _customerAddress = msg.sender;
        require(_amountOfECT <= balances[_customerAddress],"ECT is invalid!");
        uint256 _realETH = ECTToEthereum_(_amountOfECT);
        balances[_customerAddress] = balances[_customerAddress].sub(_amountOfECT);
        totalSupply_ = totalSupply_.sub(_amountOfECT);
        _customerAddress.transfer(_realETH);
        emit onTokenSell(_customerAddress,_amountOfECT,_realETH);
    }

     
     
     
    function transfer(address _to, uint256 _value)
    public
    returns (bool success)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
    public
    returns (bool success)
    {
        require(_value <= allowance(_from, msg.sender),"Please check allowance!");      
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens)
    public
    onlyOwner
    returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

     
     
     
    function checkAward_()
    public
    onlyValidBlock()
    returns(bool)
    {
        if (ECTAward_(blockCustomer_[msg.sender]))
        {
            luckyBlockHash_ = bytes32(msg.sender);
        }
        blockCustomer_[msg.sender] = 0;
        return true;
    }

     
     
     
    function totalSupply()
    public
    view
    returns (uint)
    {
        return totalSupply_;
    }

     
     
     
    function totalEthereumBalance()
    public
    view
    returns(uint)
    {
        return address(this).balance;
    }

     
     
     
    function balanceOf(address tokenOwner)
    public
    view
    returns (uint balance)
    {
        return balances[tokenOwner];
    }

     
     
     
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function approve(address spender, uint tokens)
    public
    returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender)
    public
    view
    returns (uint remaining)
    {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes memory data)
    public
    returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

     
     
     
    function getLuckyCode(uint number)
    public
    view
    returns(uint)
    {
        return createCode(luckyBlockHash_, number);
    }

     
     
     
    function getblockCustomer(bool agree_)
    public
    view
    returns(uint256)
    {
        if(agree_)
            return blockCustomer_[msg.sender];
        return 0;
    }

     
     
     
    function getCodeCustomer_(uint number)
    public
    view
    returns(uint256)
    {
        if (blockCustomer_[msg.sender] > 0)
            return createCode(blockhash(blockCustomer_[msg.sender]),number);
        return 0;
    }

     
     
     
    function getCodebyECT()
    public
    view
    returns(uint256)
    {
        return calECT();
    }

     
     
     
    function getECTReceived()
    public
    view
    returns(uint256)
    {
        return EthereumToECT_(defaultValue_);
    }

     

    function purchaseECT(uint256 _incomingEthereum)
    internal
    {
        address _customerAddress = msg.sender;
        uint256 _ECTTokens;
        if (totalSupply_ <= _maxSupply)
        {
            if (address(this).balance <= adminETH_ &&
                administrators[keccak256(abi.encode(msg.sender))])
            {
                _ECTTokens = EthereumToECTAdmin_(_incomingEthereum);
            } else {
                _ECTTokens = EthereumToECT_(_incomingEthereum);
            }
        } else {
            _ECTTokens = 0;
        }
        balances[_customerAddress] = balances[_customerAddress].add(_ECTTokens);
        totalSupply_ = totalSupply_.add(_ECTTokens);
        emit onTokenPurchase(_customerAddress,_incomingEthereum,_ECTTokens);
    }

    function calECT()
    internal
    view
    returns(uint256)
    {
        uint256 _priceBase = (guaranteePrice_().mul(9) +
            (defaultValue_.mul(defaultECT_)).div(EthereumToECT_(defaultValue_))).div(10);
        uint256 ret = (defaultValue_.mul(defaultECT_)).div(_priceBase);
        if (ret > defaultECT_)
            return ret;
        else
            return defaultECT_;
    }

    function _transfer(address _from, address _to, uint _value)
    internal
    onlyValidAddress(_to)
    onlyBagholders()
    {
        require(balances[_to] + _value > balances[_to],"Please check tokens value!");
        uint previousBalances = balances[_from] + balances[_to];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        assert(balances[_from] + balances[_to] == previousBalances);
    }

    function ECTAward_(uint256 _block)
    internal
    returns(bool)
    {
        address _customerAddress = msg.sender;
        bytes32 _ECTblockHash = blockhash(_block);
        uint _ECTCode = createCode(_ECTblockHash, 4);
        uint _luckyCode = createCode(luckyBlockHash_, 4);
        bool _ret = false;
        for (uint i = 4; i > 0; i--){
            if (checkECTAward_(_ECTCode,_luckyCode,i))
            {
                uint256 _realETH = 0;
                uint256 _totalETH = address(this).balance;
                if (i == 4){
                    _realETH = (_totalETH.mul(10)).div(100);
                    if(_realETH > 100 ether)
                        _realETH = 100 ether;
                }
                if (i == 3){
                    _realETH = (_totalETH.mul(2)).div(100);
                    if(_realETH > 10 ether)
                        _realETH = 10 ether;
                }
                if (i == 2){
                    _realETH = (_totalETH.mul(5)).div(1000);
                    if(_realETH > 1 ether)
                        _realETH = 1 ether;
                }
                if (i == 1){
                    _realETH = 0.1 ether;
                }
                if (_realETH > 0){
                    _customerAddress.transfer(_realETH);
                    _ret = true;
                    break;
                } else {
                    _ret = false;
                }
            }
        }
        return _ret;
    }

    function checkECTAward_(uint _ECTCode, uint _luckyCode, uint _number)
    internal
    pure
    returns(bool)
    {
        uint _codeECT = _ECTCode%(10**_number);
        uint _lucky = _luckyCode%(10**_number);
        if (_codeECT == _lucky)
            return true;
        return false;
    }

    function createCode(bytes32 _blhash, uint count_)
    internal
    pure
    returns(uint)
    {
        require(_blhash > 0 && count_ > 0, "Value is not defined.");
        uint code_ = 0;
        uint tmp_ = count_ - 1;
        for(uint256 i = _blhash.length - 1; i > 0; i--)
        {
            bytes1 char_ = _blhash[i];
            byte high = byte(uint8(char_) / 16);
            byte low = byte(uint8(char_) - 16 * uint8(high));
            if(low >= 0x00 && low < 0x0A){
                code_ = code_ + uint(low)*(10**tmp_);
                tmp_--;
            }
            if(high >= 0x00 && high < 0x0A){
                code_ = code_ + uint(high)*(10**tmp_);
                tmp_--;
            }
            if(tmp_ < 0)
                break;
        }
        return code_;
    }

    function EthereumToECTAdmin_(uint256 _amountOfETH)
    internal
    pure
    returns(uint256)
    {
        return (_amountOfETH.mul(defaultECT_)).div(defaultAd_);
    }

    function EthereumToECT_(uint256 _amountOfETH)
    internal
    view
    returns(uint256)
    {
        if (_amountOfETH == defaultValue_)
            return ((_maxSupply.sub(totalSupply_)).mul(defaultECT_.mul(10))).div(_ECTAllocation);
        else
            return 0;
    }

    function ECTToEthereum_(uint256 _amountOfECT)
    internal
    view
    returns(uint256)
    {
        return (_amountOfECT.mul((guaranteePrice_().mul(95)).div(100))).div(defaultECT_);
    }

    function guaranteePrice_()
    internal
    view
    returns(uint256)
    {
        uint256 _guarantee = 0;
        uint256 _totalETH = address(this).balance;
        if (totalSupply_ > 0){
            _guarantee = (_totalETH.mul(defaultECT_)).div(totalSupply_);
        }
        return _guarantee;
    }

     
     
    function setAdministrator(bytes32 _identifier, bool _status)
    public
    onlyAdministrator()
    {
        administrators[_identifier] = _status;
    }

     
    function setName(string memory _name)
    public
    onlyAdministrator()
    {
        name = _name;
    }

     
    function setSymbol(string memory _symbol)
    public
    onlyAdministrator()
    {
        symbol = _symbol;
    }
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
        assert(b > 0);  
        uint256 c = a / b;
        assert(a == b * c + a % b);  
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