 

 

pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        return a / b;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ownable {
    address public owner;

    function ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

 
contract verifiable {

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

     
    mapping(address => Signature) public signatures;

     
    function sign(uint8 v, bytes32 r, bytes32 s) public {
        signatures[msg.sender] = Signature(v, r, s);
    }

     
    function verify(address signer) public constant returns(bool) {
        bytes32 hash = keccak256(abi.encodePacked(address(this)));
        Signature storage sig = signatures[signer];
        return ecrecover(hash, sig.v, sig.r, sig.s) == signer;
    }
}

contract AssetHashToken is ownable, verifiable{
    using SafeMath for uint;

     
    struct data {
         
        string link;
         
        string hashType;
         
        string hashValue;
    }

    data public assetFile;
    data public legalFile;

     
    uint id;

     
    bool public isValid;

     
     
    bool public isSplitted;

     
     
    bool public isTradable;

     
    uint public assetPrice;

     
    string public remark1;
    string public remark2;

    mapping (address => uint) pendingWithdrawals;

     
    event TokenUpdateEvent (
        uint id,
        bool isValid,
        bool isTradable,
        address owner,
        uint assetPrice,
        string assetFileLink,
        string legalFileLink
    );

    modifier onlyUnsplitted {
        require(isSplitted == false, "This function can be called only under unsplitted status");
        _;
    }

    modifier onlyValid {
        require(isValid == true, "Contract is invaild!");
        _;
    }

     
    constructor(
        uint _id,
        address _owner,
        uint _assetPrice,
        string _assetFileUrl,
        string _assetFileHashType,
        string _assetFileHashValue,
        string _legalFileUrl,
        string _legalFileHashType,
        string _legalFileHashValue
        ) public {

        id = _id;
        owner = _owner;

        assetPrice = _assetPrice;

        initAssetFile(
            _assetFileUrl, _assetFileHashType, _assetFileHashValue, _legalFileUrl, _legalFileHashType, _legalFileHashValue);

        isValid = true;
        isSplitted = false;
        isTradable = false;
    }

     
    function initAssetFile(
        string _assetFileUrl,
        string _assetFileHashType,
        string _assetFileHashValue,
        string _legalFileUrl,
        string _legalFileHashType,
        string _legalFileHashValue
        ) internal {
        assetFile = data(
            _assetFileUrl, _assetFileHashType, _assetFileHashValue);
        legalFile = data(
            _legalFileUrl, _legalFileHashType, _legalFileHashValue);
    }

      
    function getAssetBaseInfo() public view onlyValid
        returns (
            uint _id,
            uint _assetPrice,
            bool _isTradable,
            string _remark1,
            string _remark2
        )
    {
        _id = id;
        _assetPrice = assetPrice;
        _isTradable = isTradable;

        _remark1 = remark1;
        _remark2 = remark2;
    }

     
    function setassetPrice(uint newAssetPrice)
        public
        onlyOwner
        onlyValid
        onlyUnsplitted
    {
        assetPrice = newAssetPrice;
        emit TokenUpdateEvent (
            id,
            isValid,
            isTradable,
            owner,
            assetPrice,
            assetFile.link,
            legalFile.link
        );
    }

     
    function setTradeable(bool status) public onlyOwner onlyValid onlyUnsplitted {
        isTradable = status;
        emit TokenUpdateEvent (
            id,
            isValid,
            isTradable,
            owner,
            assetPrice,
            assetFile.link,
            legalFile.link
        );
    }

     
    function setRemark1(string content) public onlyOwner onlyValid onlyUnsplitted {
        remark1 = content;
    }

     
    function setRemark2(string content) public onlyOwner onlyValid onlyUnsplitted {
        remark2 = content;
    }

     
    function setAssetFileLink(string url) public
        onlyOwner
        onlyValid
        onlyUnsplitted
    {
        assetFile.link = url;
        emit TokenUpdateEvent (
            id,
            isValid,
            isTradable,
            owner,
            assetPrice,
            assetFile.link,
            legalFile.link
        );
    }

     
    function setLegalFileLink(string url)
        public
        onlyOwner
        onlyValid
        onlyUnsplitted
    {
        legalFile.link = url;
        emit TokenUpdateEvent (
            id,
            isValid,
            isTradable,
            owner,
            assetPrice,
            assetFile.link,
            legalFile.link
        );
    }

     
    function cancelContract() public onlyOwner onlyValid onlyUnsplitted {
        isValid = false;
        emit TokenUpdateEvent (
            id,
            isValid,
            isTradable,
            owner,
            assetPrice,
            assetFile.link,
            legalFile.link
        );
    }

     
    function transferOwnership(address newowner) public onlyOwner onlyValid onlyUnsplitted {
        owner = newowner;
        isTradable = false;   

        emit TokenUpdateEvent (
            id,
            isValid,
            isTradable,
            owner,
            assetPrice,
            assetFile.link,
            legalFile.link
        );
    }


     
    function buy() public payable onlyValid onlyUnsplitted {
        require(isTradable == true, "contract is tradeable");
        require(msg.value >= assetPrice, "assetPrice not match");
        address origin_owner = owner;

        owner = msg.sender;
        isTradable = false;   

        emit TokenUpdateEvent (
            id,
            isValid,
            isTradable,
            owner,
            assetPrice,
            assetFile.link,
            legalFile.link
        );

        uint priviousBalance = pendingWithdrawals[origin_owner];
        pendingWithdrawals[origin_owner] = priviousBalance.add(assetPrice);
    }

    function withdraw() public {
        uint amount = pendingWithdrawals[msg.sender];

         
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
}

 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract DividableAsset is AssetHashToken, ERC20Interface {
    using SafeMath for uint;

    ERC20Interface stableToken;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint public _totalSupply;

    address operator;

    uint collectPrice;

    address[] internal allowners;
    mapping (address => uint) public indexOfowner;

    mapping (address => uint) public balances;
    mapping (address => mapping (address => uint)) public allowed;

    modifier onlySplitted {
        require(isSplitted == true, "Splitted status required");
        _;
    }

    modifier onlyOperator {
        require(operator == msg.sender, "Operation only permited by operator");
        _;
    }

     
    event ForceCollectEvent (
        uint id,
        uint price,
        address operator
    );

     
    event TokenSplitEvent (
        uint id,
        uint supply,
        uint8 decim,
        uint price
    );

     
    event TokenMergeEvent (
        uint id,
        address owner
    );

    constructor(
        string _name,
        string _symbol,
        address _tokenAddress,
        uint _id,
        address _owner,
        uint _assetPrice,
        string _assetFileUrl,
        string _assetFileHashType,
        string _assetFileHashValue,
        string _legalFileUrl,
        string _legalFileHashType,
        string _legalFileHashValue
        ) public
        AssetHashToken(
            _id,
            _owner,
            _assetPrice,
            _assetFileUrl,
            _assetFileHashType,
            _assetFileHashValue,
            _legalFileUrl,
            _legalFileHashType,
            _legalFileHashValue
        )
    {
        name = _name;
        symbol = _symbol;
        operator = msg.sender;  
        stableToken = ERC20Interface(_tokenAddress);
    }

     

     
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
    function allowance(address tokenOwner, address spender)
        public view
        returns (uint remaining)
    {
        return allowed[tokenOwner][spender];
    }

     
    function transfer(address to, uint tokens)
        public
        onlySplitted
        returns (bool success)
    {
        require(tokens > 0);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);


         
         
        if (indexOfowner[to] == 0) {
            allowners.push(to);
            indexOfowner[to] = allowners.length;
        }
         
        if (balances[msg.sender] == 0) {
            uint index = indexOfowner[msg.sender].sub(1);
            indexOfowner[msg.sender] = 0;

            if (index != allowners.length.sub(1)) {
                allowners[index] = allowners[allowners.length.sub(1)];
                indexOfowner[allowners[index]] = index.add(1);
            }

             
            allowners.length = allowners.length.sub(1);
        }
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

     
    function approve(address spender, uint tokens)
        public
        onlySplitted
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     
    function transferFrom(address from, address to, uint tokens)
        public
        onlySplitted
        returns (bool success)
    {
        require(tokens > 0);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);

         
         
        if (indexOfowner[to] == 0) {
            allowners.push(to);
            indexOfowner[to] = allowners.length;
        }

         
        if (balances[from] == 0) {
            uint index = indexOfowner[from].sub(1);
            indexOfowner[from] = 0;

            if (index != allowners.length.sub(1)) {
                allowners[index] = allowners[allowners.length.sub(1)];
                indexOfowner[allowners[index]] = index.add(1);
            }
             
            allowners.length = allowners.length.sub(1);
        }

        emit Transfer(from, to, tokens);
        return true;
    }

     
    function distributeDivident(uint amount) public {
         
         
        uint value = 0;
        uint length = allowners.length;
        require(stableToken.balanceOf(msg.sender) >= amount, "Insufficient balance for sender");
        require(stableToken.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance for contract");
        for (uint i = 0; i < length; i++) {
             
            value = amount.mul(balances[allowners[i]]);
            value = value.div(_totalSupply);

             
             
             
            require(stableToken.transferFrom(msg.sender, allowners[i], value));
        }
    }
    
     
    function collectAllForce(address[] _address) public onlyOperator {
         
         
        uint value = 0;
        uint length = _address.length;

        uint total_amount = 0;

        for (uint j = 0; j < length; j++) {
            if (indexOfowner[_address[j]] == 0) {
                continue;
            }

            total_amount = total_amount.add(collectPrice.mul(balances[_address[j]]));
        }

        require(stableToken.balanceOf(msg.sender) >= total_amount, "Insufficient balance for sender");
        require(stableToken.allowance(msg.sender, address(this)) >= total_amount, "Insufficient allowance for contract");

        for (uint i = 0; i < length; i++) {
             
             
             
            if (indexOfowner[_address[i]] == 0) {
                continue;
            }

            value = collectPrice.mul(balances[_address[i]]);

            require(stableToken.transferFrom(msg.sender, _address[i], value));
            balances[msg.sender] = balances[msg.sender].add(balances[_address[i]]);
            emit Transfer(_address[i], msg.sender, balances[_address[i]]);

            balances[_address[i]] = 0;

            uint index = indexOfowner[_address[i]].sub(1);
            indexOfowner[_address[i]] = 0;

            if (index != allowners.length.sub(1)) {
                allowners[index] = allowners[allowners.length.sub(1)];
                indexOfowner[allowners[index]] = index.add(1);
            }
            allowners.length = allowners.length.sub(1);
        }

        emit ForceCollectEvent(id, collectPrice, operator);
    }
    
     
    function split(uint _supply, uint8 _decim, uint _price, address[] _address, uint[] _amount)
        public
        onlyOwner
        onlyValid
        onlyUnsplitted
    {
        require(_address.length == _amount.length);

        isSplitted = true;
        _totalSupply = _supply * 10 ** uint(_decim);
        decimals = _decim;
        collectPrice = _price;

        uint amount = 0;
        uint length = _address.length;

        balances[msg.sender] = _totalSupply;
        if (indexOfowner[msg.sender] == 0) {
            allowners.push(msg.sender);
            indexOfowner[msg.sender] = allowners.length;
        }
        emit Transfer(address(0), msg.sender, _totalSupply);

        for (uint i = 0; i < length; i++) {
            amount = _amount[i];  
            balances[_address[i]] = amount;
            balances[msg.sender] = balances[msg.sender].sub(amount);

             
             
            if (indexOfowner[_address[i]] == 0) {
                allowners.push(_address[i]);
                indexOfowner[_address[i]] = allowners.length;
            }
            emit Transfer(msg.sender, _address[i], amount);
        }

        emit TokenSplitEvent(id, _supply, _decim, _price);
    }
    
     
    function merge() public onlyValid onlySplitted {
        require(balances[msg.sender] == _totalSupply);
        _totalSupply = 0;
        balances[msg.sender] = 0;
        owner = msg.sender;
        isTradable = false;
        isSplitted = false;
        emit Transfer(msg.sender, address(0), _totalSupply);
        emit TokenMergeEvent(id, msg.sender);
    }
}