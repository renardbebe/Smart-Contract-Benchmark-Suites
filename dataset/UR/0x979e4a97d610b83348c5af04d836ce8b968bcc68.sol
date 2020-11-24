 

 
 

pragma solidity 0.5.4;


 
 
 
 
interface ERC20
{
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
}


interface ERC165
{
     
     
     
     
     
     
    function supportsInterface(bytes4 interfaceID) external pure returns (bool);
}



 
 
 
interface ERC721  
{
     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    
     
     
     
     
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    
     
     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
     
     
     
     
     
    function balanceOf(address _owner) external view returns (uint256);
    
     
     
     
     
     
    function ownerOf(uint256 _tokenId) external view returns (address);
    
     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external returns (bool);
    
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external returns (bool);
    
     
     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) external returns (bool);
    
     
     
     
     
     
     
    function approve(address _approved, uint256 _tokenId) external returns (bool);
    
     
     
     
     
     
     
    function setApprovalForAll(address _operator, bool _approved) external returns (bool);
    
     
     
     
     
    function getApproved(uint256 _tokenId) external view returns (address);
    
     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC721Enumerable
{
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _tokenId);
    function tokenByIndex(uint256 _index) external view returns (uint256);
}


 
interface ERC721Metadata
{
    function name() external pure returns (string memory _name);
    function symbol() external pure returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory _uri);
}


interface ERC721TokenReceiver
{
     
     
     
     
     
     
     
     
     
     
     
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}




interface ERC223
{
    function balanceOf(address who) external view returns (uint256);
    
    function name() external pure returns (string memory _name);
    function symbol() external pure returns (string memory _symbol);
    function decimals() external pure returns (uint8 _decimals);
    function totalSupply() external view returns (uint256 _supply);
    
    function transfer(address to, uint value) external returns (bool ok);
    function transfer(address to, uint value, bytes calldata data) external returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}



interface ERC223Receiver
{
    function tokenFallback(address _from, uint256 _value, bytes calldata _data) external;
}



interface ERC777TokensRecipient
{
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}


interface ERC777TokensSender
{
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}




contract EtherPrime is ERC20, ERC721, ERC721Enumerable, ERC721Metadata, ERC165, ERC223
{
     
     
     
     
     
     
     
    
     
    uint256[] public definitePrimes;
    
     
    uint256[] public probablePrimes;
    
     
    mapping(uint256 => address) public primeToAllowedAddress;
    
     
    mapping(address => mapping(address => bool)) private ownerToOperators;
    
     
    mapping(address => uint256[]) private ownerToPrimes;
    
     
     
     
     
     
    mapping(uint256 => bytes32) private numberToNumberdata;
    
     
    mapping(uint256 => uint256) private numberToNonTwoDivisor;
    
     
    address[] public participants;
    mapping(address => uint256) private addressToParticipantsArrayIndex;
    
     
    mapping(address => uint256) public addressToGasSpent;
    mapping(address => uint256) public addressToEtherSpent;
    mapping(address => uint256) public addressToProbablePrimesClaimed;
    mapping(address => uint256) public addressToProbablePrimesDisprovenBy;
    mapping(address => uint256) public addressToProbablePrimesDisprovenFrom;

     
    uint256 public numberBeingTested;
    uint256 public divisorIndexBeingTested;
    
     
    mapping(address => uint256) public addressToEtherBalance;
    mapping(uint256 => uint256) public primeToSellOrderPrice;
    mapping(uint256 => BuyOrder[]) private primeToBuyOrders;

    
    
    
    
     
     
     
     
     
     
     
    
     
    event DefinitePrimeDiscovered(uint256 indexed prime, address indexed discoverer, uint256 indexed definitePrimesArrayIndex);
    event ProbablePrimeDiscovered(uint256 indexed prime, address indexed discoverer, uint256 indexed probablePrimesArrayIndex);
    event ProbablePrimeDisproven(uint256 indexed prime, uint256 divisor, address indexed owner, address indexed disprover, uint256 probablePrimesArrayIndex);
    
     
    event Transfer(address indexed from, address indexed to, uint256 prime);
    event Approval(address indexed owner, address indexed spender, uint256 prime);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
     
    event BuyOrderCreated(address indexed buyer, uint256 indexed prime, uint256 indexed buyOrdersArrayIndex, uint256 bid);
    event BuyOrderDestroyed(address indexed buyer, uint256 indexed prime, uint256 indexed buyOrdersArrayIndex);
    event SellPriceSet(address indexed seller, uint256 indexed prime, uint256 price);
    event PrimeTraded(address indexed seller, address indexed buyer, uint256 indexed prime, uint256 buyOrdersArrayIndex, uint256 price);
    event EtherDeposited(address indexed depositer, uint256 amount);
    event EtherWithdrawn(address indexed withdrawer, uint256 amount);
    
    
    
    
    
    
    
    
     
     
     
     
     
     
     
     
    
    function _addParticipant(address _newParticipant) private
    {
         
        if (_newParticipant != address(0x0) && addressToParticipantsArrayIndex[_newParticipant] == 0)
        {
            addressToParticipantsArrayIndex[_newParticipant] = participants.length;
            participants.push(_newParticipant);
        }
    }
    
     
     
    
    function _removePrimeFromOwnerPrimesArray(uint256 _prime) private
    {
        bytes32 numberdata = numberToNumberdata[_prime];
        uint256[] storage ownerPrimes = ownerToPrimes[numberdataToOwner(numberdata)];
        uint256 primeIndex = numberdataToOwnerPrimesIndex(numberdata);
        
         
        uint256 otherPrimeBeingMoved = ownerPrimes[ownerPrimes.length-1];
        ownerPrimes[primeIndex] = otherPrimeBeingMoved;
        _numberdataSetOwnerPrimesIndex(otherPrimeBeingMoved, uint40(primeIndex));
        
         
         
         
        ownerPrimes[ownerPrimes.length-1] = 0;  
        
         
        ownerPrimes.length--;
    }
    
    function _setOwner(uint256 _prime, address _newOwner) private
    {
        _setOwner(_prime, _newOwner, "", address(0x0), "");
    }
    
    function _setOwner(uint256 _prime, address _newOwner, bytes memory _data, address _operator, bytes memory _operatorData) private
    {
         
        address previousOwner = getOwner(_prime);
        
        if (_operator == address(0x0))
        {
            _operator = previousOwner;
        }
        
         
        if (previousOwner == _newOwner)
        {
            return;
        }
        
         
        if (previousOwner != address(0x0))
        {
            _removePrimeFromOwnerPrimesArray(_prime);
        }
        
         
        _numberdataSetOwnerAndOwnerPrimesIndex(_prime, _newOwner, uint40(ownerToPrimes[_newOwner].length));
        
         
        ownerToPrimes[_newOwner].push(_prime);
        
         
        if (primeToAllowedAddress[_prime] != address(0x0))
        {
            primeToAllowedAddress[_prime] = address(0x0);
        }
        
         
        if (primeToSellOrderPrice[_prime] != 0)
        {
            primeToSellOrderPrice[_prime] = 0;
            emit SellPriceSet(_newOwner, _prime, 0);
        }
        
         
        _addParticipant(_newOwner);
        
         
        if (isContract(_newOwner))
        {
            bool success;
            bytes32 returnValue;
            
             
            
            (success, returnValue) = _tryCall(_newOwner, abi.encodeWithSelector(ERC721TokenReceiver(_newOwner).onERC721Received.selector, _operator, previousOwner, _prime, _data));
            
            if (!success || returnValue != bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")))
            {
                 
                
                (success, returnValue) = _tryCall(_newOwner, abi.encodeWithSelector(ERC223Receiver(_newOwner).tokenFallback.selector, previousOwner, _prime, 0x0));
                
                if (!success)
                {
                     
                    
                    (success, returnValue) = _tryCall(_newOwner, abi.encodeWithSelector(ERC777TokensRecipient(_newOwner).tokensReceived.selector, _operator, previousOwner, _newOwner, _prime, _data, _operatorData));
                    
                    if (!success)
                    {
                         
                        return;
                    }
                }
            }
        }
        
        emit Transfer(previousOwner, _newOwner, _prime);
    }
    
    function _createPrime(uint256 _prime, address _owner, bool _isDefinitePrime) private
    {
         
        _numberdataSetAllPrimesIndexAndNumberType(
            _prime,
            uint48(_isDefinitePrime ? definitePrimes.length : probablePrimes.length),
            _isDefinitePrime ? NumberType.DEFINITE_PRIME : NumberType.PROBABLE_PRIME
        );
        if (_isDefinitePrime)
        {
            emit DefinitePrimeDiscovered(_prime, msg.sender, definitePrimes.length);
            definitePrimes.push(_prime);
        }
        else
        {
            emit ProbablePrimeDiscovered(_prime, msg.sender, probablePrimes.length);
            probablePrimes.push(_prime);
        }
        
         
        _setOwner(_prime, _owner);
    }
    
    
    
    
    
    
     
     
     
     
     
     
     
    
    enum NumberType
    {
        NOT_PRIME_IF_PASSED,
        NOT_PRIME,
        PROBABLE_PRIME,
        DEFINITE_PRIME
    }
    
     
    
     
     
     
     
    
    uint256 private constant NUMBERDATA_OWNER_PRIME_INDEX_SIZE = 40;
    uint256 private constant NUMBERDATA_OWNER_PRIME_INDEX_SHIFT = NUMBERDATA_ALL_PRIME_INDEX_SHIFT + NUMBERDATA_ALL_PRIME_INDEX_SIZE;
    bytes32 private constant NUMBERDATA_OWNER_PRIME_INDEX_MASK = bytes32(uint256(~uint40(0)) << NUMBERDATA_OWNER_PRIME_INDEX_SHIFT);
    
    uint256 private constant NUMBERDATA_ALL_PRIME_INDEX_SIZE = 48;
    uint256 private constant NUMBERDATA_ALL_PRIME_INDEX_SHIFT = NUMBERDATA_NUMBER_TYPE_SHIFT + NUMBERDATA_NUMBER_TYPE_SIZE;
    bytes32 private constant NUMBERDATA_ALL_PRIME_INDEX_MASK = bytes32(uint256(~uint48(0)) << NUMBERDATA_ALL_PRIME_INDEX_SHIFT);
    
    uint256 private constant NUMBERDATA_NUMBER_TYPE_SIZE = 8;
    uint256 private constant NUMBERDATA_NUMBER_TYPE_SHIFT = NUMBERDATA_OWNER_ADDRESS_SHIFT + NUMBERDATA_OWNER_ADDRESS_SIZE;
    bytes32 private constant NUMBERDATA_NUMBER_TYPE_MASK = bytes32(uint256(~uint8(0)) << NUMBERDATA_NUMBER_TYPE_SHIFT);
    
    uint256 private constant NUMBERDATA_OWNER_ADDRESS_SIZE = 160;
    uint256 private constant NUMBERDATA_OWNER_ADDRESS_SHIFT = 0;
    bytes32 private constant NUMBERDATA_OWNER_ADDRESS_MASK = bytes32(uint256(~uint160(0)) << NUMBERDATA_OWNER_ADDRESS_SHIFT);
    
    function numberdataToOwnerPrimesIndex(bytes32 _numberdata) private pure returns (uint40)
    {
        return uint40(uint256(_numberdata & NUMBERDATA_OWNER_PRIME_INDEX_MASK) >> NUMBERDATA_OWNER_PRIME_INDEX_SHIFT);
    }
    
    function numberdataToAllPrimesIndex(bytes32 _numberdata) private pure returns (uint48)
    {
        return uint48(uint256(_numberdata & NUMBERDATA_ALL_PRIME_INDEX_MASK) >> NUMBERDATA_ALL_PRIME_INDEX_SHIFT);
    }
    
    function numberdataToNumberType(bytes32 _numberdata) private pure returns (NumberType)
    {
        return NumberType(uint256(_numberdata & NUMBERDATA_NUMBER_TYPE_MASK) >> NUMBERDATA_NUMBER_TYPE_SHIFT);
    }
    
    function numberdataToOwner(bytes32 _numberdata) private pure returns (address)
    {
        return address(uint160(uint256(_numberdata & NUMBERDATA_OWNER_ADDRESS_MASK) >> NUMBERDATA_OWNER_ADDRESS_SHIFT));
    }
    
    function ownerPrimesIndex_allPrimesIndex_numberType_owner__toNumberdata(uint40 _ownerPrimesIndex, uint48 _allPrimesIndex, NumberType _numberType, address _owner) private pure returns (bytes32)
    {
        return
            bytes32(
                (uint256(_ownerPrimesIndex) << NUMBERDATA_OWNER_PRIME_INDEX_SHIFT) |
                (uint256(_allPrimesIndex) << NUMBERDATA_ALL_PRIME_INDEX_SHIFT) |
                (uint256(uint8(_numberType)) << NUMBERDATA_NUMBER_TYPE_SHIFT) |
                (uint256(uint160(_owner)) << NUMBERDATA_OWNER_ADDRESS_SHIFT)
            );
    }
    
    function _numberdataSetOwnerPrimesIndex(uint256 _number, uint40 _ownerPrimesIndex) private
    {
        bytes32 numberdata = numberToNumberdata[_number];
        numberdata &= ~NUMBERDATA_OWNER_PRIME_INDEX_MASK;
        numberdata |= bytes32(uint256(_ownerPrimesIndex)) << NUMBERDATA_OWNER_PRIME_INDEX_SHIFT;
        numberToNumberdata[_number] = numberdata;
    }
    
    function _numberdataSetAllPrimesIndex(uint256 _number, uint48 _allPrimesIndex) private
    {
        bytes32 numberdata = numberToNumberdata[_number];
        numberdata &= ~NUMBERDATA_ALL_PRIME_INDEX_MASK;
        numberdata |= bytes32(uint256(_allPrimesIndex)) << NUMBERDATA_ALL_PRIME_INDEX_SHIFT;
        numberToNumberdata[_number] = numberdata;
    }
    
    function _numberdataSetNumberType(uint256 _number, NumberType _numberType) private
    {
        bytes32 numberdata = numberToNumberdata[_number];
        numberdata &= ~NUMBERDATA_NUMBER_TYPE_MASK;
        numberdata |= bytes32(uint256(uint8(_numberType))) << NUMBERDATA_NUMBER_TYPE_SHIFT;
        numberToNumberdata[_number] = numberdata;
    }
    
     
    
    function _numberdataSetOwnerAndOwnerPrimesIndex(uint256 _number, address _owner, uint40 _ownerPrimesIndex) private
    {
        bytes32 numberdata = numberToNumberdata[_number];
        
        numberdata &= ~NUMBERDATA_OWNER_ADDRESS_MASK;
        numberdata |= bytes32(uint256(uint160(_owner))) << NUMBERDATA_OWNER_ADDRESS_SHIFT;
        
        numberdata &= ~NUMBERDATA_OWNER_PRIME_INDEX_MASK;
        numberdata |= bytes32(uint256(_ownerPrimesIndex)) << NUMBERDATA_OWNER_PRIME_INDEX_SHIFT;
        
        numberToNumberdata[_number] = bytes32(numberdata);
    }

    function _numberdataSetAllPrimesIndexAndNumberType(uint256 _number, uint48 _allPrimesIndex, NumberType _numberType) private
    {
        bytes32 numberdata = numberToNumberdata[_number];
        
        numberdata &= ~NUMBERDATA_ALL_PRIME_INDEX_MASK;
        numberdata |= bytes32(uint256(_allPrimesIndex)) << NUMBERDATA_ALL_PRIME_INDEX_SHIFT;
        
        numberdata &= ~NUMBERDATA_NUMBER_TYPE_MASK;
        numberdata |= bytes32(uint256(uint8(_numberType))) << NUMBERDATA_NUMBER_TYPE_SHIFT;
        
        numberToNumberdata[_number] = bytes32(numberdata);
    }
    

    
    

    
    
    
    
    
    
    
    
     
     
     
     
     
     
     
     
    
    function isValidNFT(uint256 _prime) private view returns (bool)
    {
        NumberType numberType = numberdataToNumberType(numberToNumberdata[_prime]);
        return numberType == NumberType.PROBABLE_PRIME || numberType == NumberType.DEFINITE_PRIME;
    }
    
    function isApprovedFor(address _operator, uint256 _prime) private view returns (bool)
    {
        address owner = getOwner(_prime);
        
        return
            (owner == _operator) ||
            (primeToAllowedAddress[_prime] == _operator) ||
            (ownerToOperators[owner][_operator] == true);
    }
    
    function isContract(address _addr) private view returns (bool)
    {
        uint256 addrCodesize;
        assembly { addrCodesize := extcodesize(_addr) }
        return addrCodesize != 0;
    }
    
    function _tryCall(address _contract, bytes memory _selectorAndArguments) private returns (bool _success, bytes32 _returnData)
    {
        bytes32[1] memory returnDataArray;
        uint256 dataLengthBytes = _selectorAndArguments.length;
        
        assembly
        {
             
            _success := call(gas(), _contract, 0, _selectorAndArguments, dataLengthBytes, returnDataArray, 32)
        }
        
        _returnData = returnDataArray[0];
    }
    
     
    function getOwner(uint256 _prime) public view returns (address)
    {
        return numberdataToOwner(numberToNumberdata[_prime]);
    }
    
    
    
    
    
    
    
    
    
     
     
     
     
     
     
     
    
    function name() external pure returns (string memory)
    {
        return "Prime number";
    }
    
    function symbol() external pure returns (string memory)
    {
        return "PRIME";
    }
    
    function decimals() external pure returns (uint8)
    {
        return 0;
    }
    
    function tokenURI(uint256 _tokenId) external view returns (string memory _uri)
    {
        require(isValidNFT(_tokenId));
        
        _uri = "https://etherprime.jesbus.com/#search:";
        
        uint256 baseURIlen = bytes(_uri).length;

         
        uint256 digits = 0;
        uint256 _currentNum = _tokenId;
        while (_currentNum != 0)
        {
            _currentNum /= 10;
            digits++;
        }
        
        uint256 divisor = 10 ** (digits-1);
        _currentNum = _tokenId;
        
        for (uint256 i=0; i<digits; i++)
        {
            uint8 digit = 0x30 + uint8(_currentNum / divisor);
            
            assembly { mstore8(add(add(_uri, 0x20), add(baseURIlen, i)), digit) }
            
            _currentNum %= divisor;
            divisor /= 10;
        }
        
        assembly { mstore(_uri, add(baseURIlen, digits)) }
    }
    
    function totalSupply() external view returns (uint256)
    {
        return definitePrimes.length + probablePrimes.length;
    }
    
    function balanceOf(address _owner) external view returns (uint256)
    {
         
        require(_owner != address(0x0), "balanceOf error: owner may not be 0x0");
        
        return ownerToPrimes[_owner].length;
    }
    
    function addressPrimeCount(address _owner) external view returns (uint256)
    {
        return ownerToPrimes[_owner].length;
    }
    
    function allowance(address _owner, address _spender) external view returns (uint256)
    {
        uint256 total = 0;
        uint256[] storage primes = ownerToPrimes[_owner];
        uint256 primesLength = primes.length;
        for (uint256 i=0; i<primesLength; i++)
        {
            uint256 prime = primes[i];
            if (primeToAllowedAddress[prime] == _spender)
            {
                total += prime;
            }
        }
        return total;
    }
    
     
    function ownerOf(uint256 _prime) external view returns (address)
    {
        address owner = getOwner(_prime);
        require(owner != address(0x0), "ownerOf error: owner is set to 0x0");
        return owner;
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _prime, bytes memory _data) public returns (bool)
    {
        require(getOwner(_prime) == _from, "safeTransferFrom error: from address does not own that prime");
        require(isApprovedFor(msg.sender, _prime), "safeTransferFrom error: you do not have approval from the owner of that prime");
        _setOwner(_prime, _to, _data, msg.sender, "");
        return true;
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _prime) external returns (bool)
    {
        return safeTransferFrom(_from, _to, _prime, "");
    }
    
    function transferFrom(address _from, address _to, uint256 _prime) external returns (bool)
    {
        return safeTransferFrom(_from, _to, _prime, "");
    }
    
    function approve(address _to, uint256 _prime) external returns (bool)
    {
        require(isApprovedFor(msg.sender, _prime), "approve error: you do not have approval from the owner of that prime");
        primeToAllowedAddress[_prime] = _to;
        emit Approval(msg.sender, _to, _prime);
        return true;
    }
    
    function setApprovalForAll(address _operator, bool _allowed) external returns (bool)
    {
        ownerToOperators[msg.sender][_operator] = _allowed;
        emit ApprovalForAll(msg.sender, _operator, _allowed);
        return true;
    }
    
    function getApproved(uint256 _prime) external view returns (address)
    {
        require(isValidNFT(_prime), "getApproved error: prime does not exist");
        return primeToAllowedAddress[_prime];
    }
    
    function isApprovedForAll(address _owner, address _operator) external view returns (bool)
    {
        return ownerToOperators[_owner][_operator];
    }
    
    function takeOwnership(uint256 _prime) external returns (bool)
    {
        require(isApprovedFor(msg.sender, _prime), "takeOwnership error: you do not have approval from the owner of that prime");
        _setOwner(_prime, msg.sender);
        return true;
    }
    
    function transfer(address _to, uint256 _prime) external returns (bool)
    {
        require(isApprovedFor(msg.sender, _prime), "transfer error: you do not have approval from the owner of that prime");
        _setOwner(_prime, _to);
        return true;
    }
    
    function transfer(address _to, uint _prime, bytes calldata _data) external returns (bool ok)
    {
        require(isApprovedFor(msg.sender, _prime), "transfer error: you do not have approval from the owner of that prime");
        _setOwner(_prime, _to, _data, msg.sender, "");
        return true;
    }
    
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256)
    {
        uint256[] storage ownerPrimes = ownerToPrimes[_owner];
        require(_index < ownerPrimes.length, "tokenOfOwnerByIndex: index out of bounds");
        return ownerPrimes[_index];
    }
    
    function tokenByIndex(uint256 _index) external view returns (uint256)
    {
        if (_index < definitePrimes.length) return definitePrimes[_index];
        else if (_index < definitePrimes.length + probablePrimes.length) return probablePrimes[_index - definitePrimes.length];
        else revert("tokenByIndex error: index out of bounds");
    }
    
    function tokensOf(address _owner) external view returns (uint256[] memory)
    {
        return ownerToPrimes[_owner];
    }
    
    function implementsERC721() external pure returns (bool)
    {
        return true;
    }
    
    function supportsInterface(bytes4 _interfaceID) external pure returns (bool)
    {
        
        if (_interfaceID == 0x01ffc9a7) return true;  
        if (_interfaceID == 0x80ac58cd) return true;  
        if (_interfaceID == 0x5b5e139f) return true;  
        if (_interfaceID == 0x780e9d63) return true;  
        return false;
    }
    
    
    
    
    
    
    
     
     
     
     
     
     
     
    
     
    function numberToDivisor(uint256 _number) public view returns (uint256)
    {
        if (_number == 0) return 0;
        else if ((_number & 1) == 0) return 2;
        else return numberToNonTwoDivisor[_number];
    }
    
    function isPrime(uint256 _number) public view returns (Booly)
    {
        NumberType numberType = numberdataToNumberType(numberToNumberdata[_number]);
        if (numberType == NumberType.DEFINITE_PRIME) return DEFINITELY;
        else if (numberType == NumberType.PROBABLE_PRIME) return PROBABLY;
        else if (numberType == NumberType.NOT_PRIME_IF_PASSED)
        {
            if (_number < numberBeingTested)
            {
                return DEFINITELY_NOT;
            }
            else
            {
                return UNKNOWN;
            }
        }
        else if (numberType == NumberType.NOT_PRIME) return DEFINITELY_NOT;
        else revert();
    }
    
    function getPrimeFactors(uint256 _number) external view returns (bool _success, uint256[] memory _primeFactors)
    {
        _primeFactors = new uint256[](0);
        if (_number == 0) { _success = false; return (_success, _primeFactors); }
        
         
        uint256 amount = 0;
        
        
        uint256 currentNumber = _number;
        
        while (true)
        {
             
            if (currentNumber == 1) { _success = true; return (_success, _primeFactors); }
            
            uint256 divisor = numberToDivisor(currentNumber);
            
            if (divisor == 0)
            {
                if (isPrime(currentNumber) == DEFINITELY)
                {
                     
                     
                     
                     
                    divisor = currentNumber;
                }
                else
                {
                     
                     
                    _success = false;
                    return (_success, _primeFactors);
                }
            }
            else
            {
                while (isPrime(divisor) != DEFINITELY)
                {
                    divisor = numberToDivisor(divisor);
                    if (divisor == 0) { _success = false; return (_success, _primeFactors); }
                }
            }
            
            currentNumber /= divisor;
            
             
            {
                amount++;
                assembly
                {
                    mstore(0x40, add(mload(0x40), 0x20))  
                    mstore(_primeFactors, amount)  
                }
                _primeFactors[amount-1] = divisor;
            }
        }
    }
    
     

    function amountOfParticipants() external view returns (uint256)
    {
        return participants.length;
    }
    
    function amountOfPrimesOwnedByOwner(address owner) external view returns (uint256)
    {
        return ownerToPrimes[owner].length;
    }
    
    function amountOfPrimesFound() external view returns (uint256)
    {
        return definitePrimes.length + probablePrimes.length;
    }
    
    function amountOfDefinitePrimesFound() external view returns (uint256)
    {
        return definitePrimes.length;
    }
    
    function amountOfProbablePrimesFound() external view returns (uint256)
    {
        return probablePrimes.length;
    }
    
    function largestDefinitePrimeFound() public view returns (uint256)
    {
        return definitePrimes[definitePrimes.length-1];
    }
    
    function getInsecureRandomDefinitePrime() external view returns (uint256)
    {
        return definitePrimes[insecureRand()%definitePrimes.length];
    }
    
    function getInsecureRandomProbablePrime() external view returns (uint256)
    {
        return probablePrimes[insecureRand()%probablePrimes.length];
    }



    
     
     
     
     
     
     
     
    
    constructor() public
    {
        participants.push(address(0x0));
        
         
        _createPrime(2, msg.sender, true);
        
         
        numberBeingTested = 3;
        divisorIndexBeingTested = 0;
        
        new EtherPrimeChat(this);
    }
    
    

    
    
    
     
     
     
     
     
     
     
    
     
     
    
    uint256 private constant DEFAULT_PRIMES_TO_MEMORIZE = 0;
    uint256 private constant DEFAULT_LOW_LEVEL_GAS = 200000;
    
    function () external
    {
        computeWithParams(definitePrimes.length/2, DEFAULT_LOW_LEVEL_GAS, msg.sender);
    }
    
    function compute() external
    {
        computeWithParams(definitePrimes.length/2, DEFAULT_LOW_LEVEL_GAS, msg.sender);
    }
    
    function computeAndGiveTo(address _recipient) external
    {
        computeWithParams(definitePrimes.length/2, DEFAULT_LOW_LEVEL_GAS, _recipient);
    }
    
    function computeWithPrimesToMemorize(uint256 _primesToMemorize) external
    {
        computeWithParams(_primesToMemorize, DEFAULT_LOW_LEVEL_GAS, msg.sender);
    }
    
    function computeWithPrimesToMemorizeAndLowLevelGas(uint256 _primesToMemorize, uint256 _lowLevelGas) external
    {
        computeWithParams(_primesToMemorize, _lowLevelGas, msg.sender);
    }
    
    function computeWithParams(uint256 _primesToMemorize, uint256 _lowLevelGas, address _recipient) public
    {
        require(_primesToMemorize <= definitePrimes.length, "computeWithParams error: _primesToMemorize out of bounds");
        
        uint256 startGas = gasleft();
        
         
        uint256 number = numberBeingTested;
        uint256 divisorIndex = divisorIndexBeingTested;
        
         
        uint256 totalPrimes = definitePrimes.length;
        
         
        uint256[] memory definitePrimesCache = new uint256[](_primesToMemorize);
        for (uint256 i=0; i<_primesToMemorize; i++)
        {
            definitePrimesCache[i] = definitePrimes[i];
        }
        
        for (; ; number += 2)
        {
             
            if (gasleft() < _lowLevelGas)
            {
                numberBeingTested = number;
                divisorIndexBeingTested = divisorIndex;
                uint256 gasSpent = startGas - gasleft();
                addressToGasSpent[msg.sender] += gasSpent;
                addressToEtherSpent[msg.sender] += gasSpent * tx.gasprice;
                return;
            }
            
            if (isPrime(number) != DEFINITELY_NOT)
            {
                uint256 sqrtNumberRoundedDown = sqrtRoundedDown(number);
                
                bool numberCanStillBePrime = true;
                uint256 divisor;
                
                for (; divisorIndex<totalPrimes; divisorIndex++)
                {
                     
                    if (gasleft() < _lowLevelGas)
                    {
                        numberBeingTested = number;
                        divisorIndexBeingTested = divisorIndex;
                        uint256 gasSpent = startGas - gasleft();
                        addressToGasSpent[msg.sender] += gasSpent;
                        addressToEtherSpent[msg.sender] += gasSpent * tx.gasprice;
                        return;
                    }
                    
                    if (divisorIndex < definitePrimesCache.length) divisor = definitePrimesCache[divisorIndex];
                    else divisor = definitePrimes[divisorIndex];
                    
                    if (number % divisor == 0)
                    {
                        numberCanStillBePrime = false;
                        break;
                    }
                    
                     
                     
                     
                     
                     
                     
                     
                     
                    if (divisor > sqrtNumberRoundedDown)
                    {
                        break;
                    }
                }
                
                if (numberCanStillBePrime)
                {
                    _createPrime(number, _recipient, true);
                    totalPrimes++;
                }
                else
                {
                    numberToNonTwoDivisor[number] = divisor;
                }
                
                 
                 
                divisorIndex = 1;
            }
        }
        
         
        revert("computeWithParams error: This point should never be reached.");
    }
    
     
    function sqrtRoundedDown(uint256 x) private pure returns (uint256 y)
    {
        if (x == ~uint256(0)) return 340282366920938463463374607431768211455;
        
        uint256 z = (x + 1) >> 1;
        y = x;
        while (z < y)
        {
            y = z;
            z = ((x / z) + z) >> 1;
        }
        return y;
    }
    
    
    
    
    
    
     
     
     
     
     
     
     
    
     
    function isBalancedPrime(uint256 _prime) external view returns (Booly result, uint256 lowerPrime, uint256 higherPrime)
    {
        Booly primality = isPrime(_prime);
        if (primality == DEFINITELY_NOT)
        {
            return (DEFINITELY_NOT, 0, 0);
        }
        else if (primality == PROBABLY_NOT)
        {
            return (PROBABLY_NOT, 0, 0);
        }
        else if (primality == UNKNOWN)
        {
            return (UNKNOWN, 0, 0);
        }
        else if (primality == PROBABLY)
        {
            return (UNKNOWN, 0, 0);
        }
        else if (primality == DEFINITELY)
        {
            uint256 index = numberdataToAllPrimesIndex(numberToNumberdata[_prime]);
            if (index == 0)
            {
                 
                return (DEFINITELY_NOT, 0, 0);
            }
            else if (index == definitePrimes.length-1)
            {
                 
                return (UNKNOWN, 0, 0);
            }
            else
            {
                uint256 primeBefore = definitePrimes[index-1];
                uint256 primeAfter = definitePrimes[index+1];
                if (_prime - primeBefore == primeAfter - _prime) return (DEFINITELY, primeBefore, primeAfter);
                else return (DEFINITELY_NOT, primeBefore, primeAfter);
            }
        }
        else
        {
            revert();
        }
    }
    
     
     
     
     
     
     
    function isNTupleMersennePrime(uint256 _number, uint256 _n) external view returns (Booly _result, uint256[] memory _powers)
    {
        _powers = new uint256[](_n);
        
         
        if (_number+1 < _number) return (UNKNOWN, _powers);
        
        _result = isPrime(_number);
        if (_result == DEFINITELY_NOT) { return (DEFINITELY_NOT, _powers); }
        
        uint256 currentNumber = _number;
        
        for (uint256 i=0; i<_n; i++)
        {
            Booly powerOf2ity = isPowerOf2(currentNumber+1) ? DEFINITELY : DEFINITELY_NOT;
            if (powerOf2ity == DEFINITELY_NOT) { return (DEFINITELY_NOT, _powers); }
            
            _powers[i] = currentNumber = log2ofPowerOf2(currentNumber+1);
        }
        
        return (_result, _powers);
    }
    
     
    function isGoodPrime(uint256 _number) external view returns (Booly)
    {
         
        if (_number == 2) return DEFINITELY_NOT;
        
        Booly primality = isPrime(_number);
        if (primality == DEFINITELY)
        {
            uint256 index = numberdataToAllPrimesIndex(numberToNumberdata[_number]);
            
            if (index*2 >= definitePrimes.length)
            {
                 
                return UNKNOWN;
            }
            else
            {
                uint256 squareOfInput;
                bool mulSuccess;
                
                (squareOfInput, mulSuccess) = TRY_MUL(_number, _number);
                if (!mulSuccess) return UNKNOWN;
                
                for (uint256 i=1; i<=index; i++)
                {
                    uint256 square;
                    (square, mulSuccess) = TRY_MUL(definitePrimes[index-i], definitePrimes[index+i]);
                    if (!mulSuccess) return UNKNOWN;
                    if (square >= squareOfInput)
                    {
                        return DEFINITELY_NOT;
                    }
                }
                return DEFINITELY;
            }
        }
        else if (primality == PROBABLY || primality == UNKNOWN)
        {
             
            return UNKNOWN;
        }
        else if (primality == DEFINITELY_NOT)
        {
            return DEFINITELY_NOT;
        }
        else if (primality == PROBABLY_NOT)
        {
            return PROBABLY_NOT;
        }
        else
        {
             
            revert();
        }
    }
    
     
    function isFactorialPrime(uint256 _number) external view returns (Booly _result, uint256 _n, int256 _delta)
    {
         
        if (_number == 0) return (DEFINITELY_NOT, 0, 0);
        
         
        if (_number == ~uint256(0)) return (DEFINITELY_NOT, 0, 0);
        
        
        Booly primality = isPrime(_number);
        
        if (primality == DEFINITELY_NOT) return (DEFINITELY_NOT, 0, 0);
        
        bool factorialityOfPrimePlus1;
        uint256 primePlus1n;

         
        (primePlus1n, factorialityOfPrimePlus1) = reverseFactorial(_number+1);
        if (factorialityOfPrimePlus1) return (AND(primality, factorialityOfPrimePlus1), primePlus1n, -1);

        bool factorialityOfPrimeMinus1;
        uint256 primeMinus1n;
        
        (primeMinus1n, factorialityOfPrimeMinus1) = reverseFactorial(_number-1);
        if (factorialityOfPrimeMinus1) return (AND(primality, factorialityOfPrimeMinus1), primeMinus1n, 1);
        
        return (DEFINITELY_NOT, 0, 0);
    }
    
     
    function isCullenPrime(uint256 _number) external pure returns (Booly _result, uint256 _n)
    {
         
        if (_number == 3)   
        {
            return (DEFINITELY, 1);
        }
        else if (_number == 393050634124102232869567034555427371542904833)  
        {
            return (DEFINITELY, 141);
        }
        else
        {
            return (DEFINITELY_NOT, 0);
        }
    }
    
     
     
    function isFermatPrime(uint256 _number) external view returns (Booly result, uint256 _2_pow_n, uint256 _n)
    {
         
        if (_number == 0) return (DEFINITELY_NOT, 0, 0);
        
        
        Booly primality = isPrime(_number);
        
        if (primality == DEFINITELY_NOT) return (DEFINITELY_NOT, 0, 0);
        
        bool is__2_pow_2_pow_n__powerOf2 = isPowerOf2(_number-1);
        
        if (!is__2_pow_2_pow_n__powerOf2) return (DEFINITELY_NOT, 0, 0);
        
        _2_pow_n = log2ofPowerOf2(_number-1);
        
        bool is__2_pow_n__powerOf2 = isPowerOf2(_2_pow_n);
        
        if (!is__2_pow_n__powerOf2) return (DEFINITELY_NOT, _2_pow_n, 0);
        
        _n = log2ofPowerOf2(_2_pow_n);
    }
    
     
    function isSuperPrime(uint256 _number) public view returns (Booly _result, uint256 _indexStartAtOne)
    {
        Booly primality = isPrime(_number);
        if (primality == DEFINITELY)
        {
            _indexStartAtOne = numberdataToAllPrimesIndex(numberToNumberdata[_number]) + 1;
            _result = isPrime(_indexStartAtOne);
            return (_result, _indexStartAtOne);
        }
        else if (primality == DEFINITELY_NOT)
        {
            return (DEFINITELY_NOT, 0);
        }
        else if (primality == UNKNOWN)
        {
            return (UNKNOWN, 0);
        }
        else if (primality == PROBABLY)
        {
            return (UNKNOWN, 0);
        }
        else if (primality == PROBABLY_NOT)
        {
            return (PROBABLY_NOT, 0);
        }
        else
        {
            revert();
        }
    }
    
    function isFibonacciPrime(uint256 _number) public view returns (Booly _result)
    {
        return AND_F(isPrime, isFibonacciNumber, _number);
    }
    
    
    
    
    
    
    
    
     
     
     
     
     
     
     
    
    function isFibonacciNumber(uint256 _number) public pure returns (Booly _result)
    {
         
         
         
         
         
         

        if (uint256(uint120(_number)) != _number) return UNKNOWN;
        
        uint256 squareOfNumber = _number * _number;
        uint256 squareTimes5 = squareOfNumber * 5;
        uint256 squareTimes5plus4 = squareTimes5 + 4;
        
        bool squareTimes5plus4squarality;
        (squareTimes5plus4squarality, ) = isSquareNumber(squareTimes5plus4);
        
        if (squareTimes5plus4squarality) return DEFINITELY;
        
        uint256 squareTimes5minus4 = squareTimes5 - 4;
        
        bool squareTimes5minus4squarality;
        
         
        if (squareTimes5minus4 > squareTimes5) 
        {
            squareTimes5minus4squarality = false;
        }
        else
        {
            (squareTimes5minus4squarality, ) = isSquareNumber(squareTimes5minus4);
        }
        
        return (squareTimes5plus4squarality || squareTimes5minus4squarality) ? DEFINITELY : DEFINITELY_NOT;
    }
    
    function isSquareNumber(uint256 _number) private pure returns (bool _result, uint256 _squareRoot)
    {
        uint256 rootRoundedDown = sqrtRoundedDown(_number);
        return (rootRoundedDown * rootRoundedDown == _number, rootRoundedDown);
    }
    






    
     
     
     
     
     
     
     
    
    function reverseFactorial(uint256 _number) private pure returns (uint256 output, bool success)
    {
         
        if (_number == 0) return (0, false);
        
        uint256 divisor = 1;
        while (_number > 1)
        {
            divisor++;
            uint256 remainder = _number % divisor;
            if (remainder != 0) return (divisor, false);
            _number /= divisor;
        }
        
        return (divisor, true);
    }
    
    function isPowerOf2(uint256 _number) private pure returns (bool)
    {
        if (_number == 0) return false;
        else return ((_number-1) & _number) == 0;
    }
    
     
     
    function log2ofPowerOf2(uint256 _powerOf2) private pure returns (uint256)
    {
        require(_powerOf2 != 0, "log2ofPowerOf2 error: 0 is not a power of 2");
        uint256 iterations = 0;
        while (true)
        {
            if (_powerOf2 == 1) return iterations;
            require((_powerOf2 & 1) == 0, "log2ofPowerOf2 error: argument is not a power of 2");  
            _powerOf2 >>= 1;  
            iterations++;
        }
    }
    
     
     
    function insecureRand() private view returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(
            largestDefinitePrimeFound(),
            probablePrimes.length,
            block.coinbase,
            block.timestamp,
            block.number,
            block.difficulty,
            tx.origin,
            tx.gasprice,
            msg.sender,
            now,
            gasleft()
        )));
    }
    
     
    function TRY_POW_MOD(uint256 _base, uint256 _power, uint256 _modulus) private pure returns (uint256 result, bool success)
    {
        if (_modulus == 0) return (0, false);
        
        bool mulSuccess;
        _base %= _modulus;
        result = 1;
        while (_power > 0)
        {
            if (_power & uint256(1) != 0)
            {
                (result, mulSuccess) = TRY_MUL(result, _base);
                if (!mulSuccess) return (0, false);
                result %= _modulus;
            }
            (_base, mulSuccess) = TRY_MUL(_base, _base);
            if (!mulSuccess) return (0, false);
            _base = _base % _modulus;
            _power >>= 1;
        }
        success = true;
    }
    
    function TRY_MUL(uint256 _i, uint256 _j) private pure returns (uint256 result, bool success)
    {
        if (_i == 0) { return (0, true); }
        uint256 ret = _i * _j;
        if (ret / _i == _j) return (ret, true);
        else return (ret, false);
    }




    
     
     
     
     
     
     
     
    
     
     
     
    function probabilisticTest(uint256 d, uint256 _number, uint256 _random) private pure returns (bool result, bool success)
    {
         
        assert(d & 1 == 1);  
        assert((_number-1) % d == 0);  
        uint256 nMinusOneOverD = (_number-1) / d;
        assert(isPowerOf2(nMinusOneOverD));  
        assert(nMinusOneOverD >= 1);  
        
         
        if (_number < 4) return (false, false);
        
         
        uint256 a = 2 + _random % (_number - 4);
        
         
        uint256 x;
        (x, success) = TRY_POW_MOD(a, d, _number);
        if (!success) return (false, false);
        
        if (x == 1 || x == _number-1)
        {
            return (true, true);
        }
        
         
         
         
         
         
        while (d != _number-1)
        {
            (x, success) = TRY_MUL(x, x);
            if (!success) return (false, false);
            
            x %= _number;
            
            (d, success) = TRY_MUL(d, 2);
            if (!success) return (false, false);
            
            
            if (x == 1) return (false, true);
            if (x == _number-1) return (true, true);
        }
     
         
        return (false, true);
    }
    
     
     
     
    function isPrime_probabilistic(uint256 _number) public view returns (Booly)
    {
         
        uint256 probabilistic_iterations = 40;
        
         
        if (_number == 0 || _number == 1 || _number == 4)  return DEFINITELY_NOT;
        if (_number == 2 || _number == 3) return DEFINITELY;
        
         
        uint256 d = _number - 1;
        while ((d & 1) == 0)
        {
            d >>= 1;
        }
        
        uint256 random = insecureRand();
        
         
        for (uint256 i = 0; i < probabilistic_iterations; i++)
        {
            bool result;
            bool success;
            (result, success) = probabilisticTest(d, _number, random);
            if (success == false)
            {
                return UNKNOWN;
            }
            if (result == false)
            {
                return DEFINITELY_NOT;
            }
            
             
            random *= 22777;
            random ^= (random >> 7);
            random *= 71879;
            random ^= (random >> 11);
        }
        
        return PROBABLY;
    }
    
    
    
    
    
    
     
     
     
     
     
     
     
    
    function claimProbablePrime(uint256 _number) public
    {
        require(tryClaimProbablePrime(_number), "claimProbablePrime error: that number is not prime or has already been claimed");
    }
    
    function tryClaimProbablePrime(uint256 _number) public returns (bool _success)
    {
        uint256 startGas = gasleft();
        
        Booly primality = isPrime(_number);
        
         
        if (primality != UNKNOWN)
        {
            _success = false;
        }
        else
        {
            primality = isPrime_probabilistic(_number);
            
            if (primality == DEFINITELY_NOT)
            {
                 
                _numberdataSetNumberType(_number, NumberType.NOT_PRIME);
                
                 _success = false;
            }
            else if (primality == PROBABLY)
            {
                _createPrime(_number, msg.sender, false);
                
                addressToProbablePrimesClaimed[msg.sender]++;
                
                 _success = true;
            }
            else
            {
                 _success = false;
            }
        }
        
        uint256 gasSpent = startGas - gasleft();
        addressToGasSpent[msg.sender] += gasSpent;
        addressToEtherSpent[msg.sender] += gasSpent * tx.gasprice;
    }
    
    function disproveProbablePrime(uint256 _prime, uint256 _divisor) external
    {
        require(_divisor > 1 && _divisor < _prime, "disproveProbablePrime error: divisor must be greater than 1 and smaller than prime");
        
        bytes32 numberdata = numberToNumberdata[_prime];
        
         
        require(numberdataToNumberType(numberdata) == NumberType.PROBABLE_PRIME, "disproveProbablePrime error: that prime is not a probable prime");
        
         
        require((_prime % _divisor) == 0, "disproveProbablePrime error: that prime is not divisible by that divisor");
        
        address owner = numberdataToOwner(numberdata);
        
         
        addressToProbablePrimesDisprovenFrom[owner]++;
        addressToProbablePrimesDisprovenBy[msg.sender]++;
        
        _setOwner(_prime, address(0x0));
        
        _numberdataSetNumberType(_prime, NumberType.NOT_PRIME);
        
         
        uint256 primeIndex = numberdataToAllPrimesIndex(numberdata);
        
         
        if (primeIndex < probablePrimes.length-1)
        {
             
            uint256 otherPrimeBeingMoved = probablePrimes[probablePrimes.length-1];
            _numberdataSetAllPrimesIndex(otherPrimeBeingMoved, uint48(primeIndex));
            probablePrimes[primeIndex] = otherPrimeBeingMoved;
        }
        probablePrimes[probablePrimes.length-1] = 0;  
        probablePrimes.length--;
        
         
        emit ProbablePrimeDisproven(_prime, _divisor, owner, msg.sender, primeIndex);
        
         
        numberToNonTwoDivisor[_prime] = _divisor;
    }
    
    function claimProbablePrimeInRange(uint256 _start, uint256 _end) external returns (bool _success, uint256 _prime)
    {
        for (uint256 currentNumber = _start; currentNumber <= _end; currentNumber++)
        {
            if (tryClaimProbablePrime(currentNumber)) { return (true, currentNumber); }
        }
        return (false, 0);
    }
    
    
    
    
    
     
     
     
     
     
     
     
     
     
    
    function onERC721Received(address, address, uint256, bytes calldata) external pure  
    {
        revert("EtherPrime contract should not receive tokens");
    }
    
    function tokenFallback(address, uint256, bytes calldata) external pure  
    {
        revert("EtherPrime contract should not receive tokens");
    }
    
    function tokensReceived(address, address, address, uint, bytes calldata, bytes calldata) external pure  
    {
        revert("EtherPrime contract should not receive tokens");
    }
    
    
    
    
    
    
    
     
     
     
     
     
     
     
    
     
    
    enum Booly
    {
        DEFINITELY_NOT,
        PROBABLY_NOT,
        UNKNOWN,
        PROBABLY,
        DEFINITELY
    }
    
    Booly public constant DEFINITELY_NOT = Booly.DEFINITELY_NOT;
    Booly public constant PROBABLY_NOT = Booly.PROBABLY_NOT;
    Booly public constant UNKNOWN = Booly.UNKNOWN;
    Booly public constant PROBABLY = Booly.PROBABLY;
    Booly public constant DEFINITELY = Booly.DEFINITELY;
    
    function OR(Booly a, Booly b) internal pure returns (Booly)
    {
        if (a == DEFINITELY || b == DEFINITELY) return DEFINITELY;
        else if (a == PROBABLY || b == PROBABLY) return PROBABLY;
        else if (a == UNKNOWN || b == UNKNOWN) return UNKNOWN;
        else if (a == PROBABLY_NOT || b == PROBABLY_NOT) return PROBABLY_NOT;
        else if (a == DEFINITELY_NOT && b == DEFINITELY_NOT) return DEFINITELY_NOT;
        else revert();
    }
    
    function NOT(Booly a) internal pure returns (Booly)
    {
        if (a == DEFINITELY_NOT) return DEFINITELY;
        else if (a == PROBABLY_NOT) return PROBABLY;
        else if (a == UNKNOWN) return UNKNOWN;
        else if (a == PROBABLY) return PROBABLY_NOT;
        else if (a == DEFINITELY) return DEFINITELY_NOT;
        else revert();
    }
    
    function AND(Booly a, Booly b) internal pure returns (Booly)
    {
        if (a == DEFINITELY_NOT || b == DEFINITELY_NOT) return DEFINITELY_NOT;
        else if (a == PROBABLY_NOT || b == PROBABLY_NOT) return PROBABLY_NOT;
        else if (a == UNKNOWN || b == UNKNOWN) return UNKNOWN;
        else if (a == PROBABLY || b == PROBABLY) return PROBABLY;
        else if (a == DEFINITELY && b == DEFINITELY) return DEFINITELY;
        else revert();
    }
    
    function AND(Booly a, bool b) internal pure returns (Booly)
    {
        if (b == true) return a;
        else return DEFINITELY_NOT;
    }
    
    function XOR(Booly a, Booly b) internal pure returns (Booly)
    {
        return AND(OR(a, b), NOT(AND(a, b)));
    }
    
    function NAND(Booly a, Booly b) internal pure returns (Booly)
    {
        return NOT(AND(a, b));
    }
    
    function NOR(Booly a, Booly b) internal pure returns (Booly)
    {
        return NOT(OR(a, b));
    }
    
    function XNOR(Booly a, Booly b) internal pure returns (Booly)
    {
        return NOT(XOR(a, b));
    }
    
    function AND_F(function(uint256)view returns(Booly) aFunc, function(uint256)view returns(Booly) bFunc, uint256 _arg) internal view returns (Booly)
    {
        Booly a = aFunc(_arg);
        if (a == DEFINITELY_NOT) return DEFINITELY_NOT;
        else
        {
            Booly b = bFunc(_arg);
            if (b == DEFINITELY_NOT) return DEFINITELY_NOT;
            else if (a == PROBABLY_NOT) return PROBABLY_NOT;
            else if (b == PROBABLY_NOT) return PROBABLY_NOT;
            else if (a == UNKNOWN || b == UNKNOWN) return UNKNOWN;
            else if (a == PROBABLY || b == PROBABLY) return PROBABLY;
            else if (a == DEFINITELY && b == DEFINITELY) return DEFINITELY;
            else revert();
        }
    }
    
    function OR_F(function(uint256)view returns(Booly) aFunc, function(uint256)view returns(Booly) bFunc, uint256 _arg) internal view returns (Booly)
    {
        Booly a = aFunc(_arg);
        if (a == DEFINITELY) return DEFINITELY;
        else
        {
            Booly b = bFunc(_arg);
            if (b == DEFINITELY) return DEFINITELY;
            else if (a == PROBABLY || b == PROBABLY) return PROBABLY;
            else if (a == UNKNOWN || b == UNKNOWN) return UNKNOWN;
            else if (a == PROBABLY_NOT || b == PROBABLY_NOT) return PROBABLY_NOT;
            else if (a == DEFINITELY_NOT && b == DEFINITELY_NOT) return DEFINITELY_NOT;
            else revert();
        }
    }
    
    
    
    
    
    
    
    
     
     
     
     
     
     
     
    
     
    function depositEther() public payable
    {
        addressToEtherBalance[msg.sender] += msg.value;
        
        emit EtherDeposited(msg.sender, msg.value);
    }
    
    function withdrawEther(uint256 _amount) public
    {
        require(addressToEtherBalance[msg.sender] >= _amount, "withdrawEther error: insufficient balance to withdraw that much ether");
        addressToEtherBalance[msg.sender] -= _amount;
        msg.sender.transfer(_amount);
        
        emit EtherWithdrawn(msg.sender, _amount);
    }
    
    struct BuyOrder
    {
        address buyer;
        uint256 bid;
    }
    
    function depositEtherAndCreateBuyOrder(uint256 _prime, uint256 _bid, uint256 _indexHint) external payable
    {
        depositEther();
        
        require(_bid > 0, "createBuyOrder error: bid must be greater than 0");
        require(_prime >= 2, "createBuyOrder error: prime must be greater than or equal to 2");
        
        BuyOrder[] storage buyOrders = primeToBuyOrders[_prime];

        uint256 _index;
        
        if (_indexHint == buyOrders.length)
        {
            _index = _indexHint;
        }
        else if (_indexHint < buyOrders.length &&
                 buyOrders[_indexHint].buyer == address(0x0) &&
                 buyOrders[_indexHint].bid == 0)
        {
            _index = _indexHint;
        }
        else
        {
            _index = findFreeBuyOrderSlot(_prime);
        }
        
        if (_index == buyOrders.length)
        {
            buyOrders.length++;
        }
        
        BuyOrder storage buyOrder = buyOrders[_index];
        
        buyOrder.buyer = msg.sender;
        buyOrder.bid = _bid;
        
        emit BuyOrderCreated(msg.sender, _prime, _index, _bid);
        
        tryMatchSellAndBuyOrdersRange(_prime, _index, _index);
    }
    
    function modifyBuyOrder(uint256 _prime, uint256 _index, uint256 _newBid) external
    {
        BuyOrder[] storage buyOrders = primeToBuyOrders[_prime];
        require(_index < buyOrders.length, "modifyBuyOrder error: index out of bounds");
        
        BuyOrder storage buyOrder = buyOrders[_index];
        require(buyOrder.buyer == msg.sender, "modifyBuyOrder error: you do not own that buy order");
        
        emit BuyOrderDestroyed(msg.sender, _prime, _index);
        
        buyOrder.bid = _newBid;
        
        emit BuyOrderCreated(msg.sender, _prime, _index, _newBid);
    }
    

    function tryCancelBuyOrders(uint256[] memory _primes, uint256[] memory _buyOrderIndices) public returns (uint256 _amountCancelled)
    {
        require(_primes.length == _buyOrderIndices.length, "tryCancelBuyOrders error: invalid input, arrays are not the same length");
        
        _amountCancelled = 0;
        
        for (uint256 i=0; i<_primes.length; i++)
        {
            uint256 index = _buyOrderIndices[i];
            uint256 prime = _primes[i];
            
            BuyOrder[] storage buyOrders = primeToBuyOrders[prime];
            if (index < buyOrders.length)
            {
                BuyOrder storage buyOrder = buyOrders[index];
                if (buyOrder.buyer == msg.sender)
                {
                    emit BuyOrderDestroyed(msg.sender, prime, index);
                    
                    buyOrder.buyer = address(0x0);
                    buyOrder.bid = 0;
                    
                    _amountCancelled++;
                }
            }
        }
    }

    function setSellPrice(uint256 _prime, uint256 _price, uint256 _matchStartBuyOrderIndex, uint256 _matchEndBuyOrderIndex) external returns (bool _sold)
    {
        require(isApprovedFor(msg.sender, _prime), "createSellOrder error: you do not have ownership of or approval for that prime");
        
        primeToSellOrderPrice[_prime] = _price;
        
        emit SellPriceSet(msg.sender, _prime, _price);
        
        if (_matchStartBuyOrderIndex != ~uint256(0))
        {
            return tryMatchSellAndBuyOrdersRange(_prime, _matchStartBuyOrderIndex, _matchEndBuyOrderIndex);
        }
        else
        {
            return false;
        }
    }

    function tryMatchSellAndBuyOrdersRange(uint256 _prime, uint256 _startBuyOrderIndex, uint256 _endBuyOrderIndex) public returns (bool _sold)
    {
        uint256 sellOrderPrice = primeToSellOrderPrice[_prime];
        address seller = getOwner(_prime);
        
        if (sellOrderPrice == 0 ||
            seller == address(0x0))
        {
            return false;
        }
        else
        {
            BuyOrder[] storage buyOrders = primeToBuyOrders[_prime];
            
            uint256 buyOrders_length = buyOrders.length;

            if (_startBuyOrderIndex > _endBuyOrderIndex ||
                _endBuyOrderIndex >= buyOrders.length)
            {
                return false;
            }
            else
            {
                for (uint256 i=_startBuyOrderIndex; i<=_endBuyOrderIndex && i<buyOrders_length; i++)
                {
                    BuyOrder storage buyOrder = buyOrders[i];
                    address buyer = buyOrder.buyer;
                    uint256 bid = buyOrder.bid;
                    
                    if (bid >= sellOrderPrice &&
                        addressToEtherBalance[buyer] >= bid)
                    {
                        addressToEtherBalance[buyer] -= bid;
                        addressToEtherBalance[seller] += bid;
                        
                        _setOwner(_prime, buyer);  
                        
                        emit BuyOrderDestroyed(buyer, _prime, i);
                        emit PrimeTraded(seller, buyer, _prime, i, bid);
                        
                        buyOrder.buyer = address(0x0);
                        buyOrder.bid = 0;
                        return true;
                    }
                }
                return false;
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
     
     
     
     
     
     
     
    
    function countPrimeBuyOrders(uint256 _prime) external view returns (uint256 _amountOfBuyOrders)
    {
        _amountOfBuyOrders = 0;
        
        BuyOrder[] storage buyOrders = primeToBuyOrders[_prime];
        for (uint256 i=0; i<buyOrders.length; i++)
        {
            if (buyOrders[i].buyer != address(0x0))
            {
                _amountOfBuyOrders++;
            }
        }
    }
    
    function lengthOfPrimeBuyOrdersArray(uint256 _prime) external view returns (uint256 _lengthOfPrimeBuyOrdersArray)
    {
        return primeToBuyOrders[_prime].length;
    }
    
    function getPrimeBuyOrder(uint256 _prime, uint256 _index) external view returns (address _buyer, uint256 _bid, bool _buyerHasEnoughFunds)
    {
       BuyOrder storage buyOrder = primeToBuyOrders[_prime][_index];
       
       _buyer = buyOrder.buyer;
       _bid = buyOrder.bid;
       
       require(_buyer != address(0x0) && _bid != 0);
       
       _buyerHasEnoughFunds = addressToEtherBalance[_buyer] >= _bid;
    }
    
    function findFreeBuyOrderSlot(uint256 _prime) public view returns (uint256 _buyOrderSlotIndex)
    {
        BuyOrder[] storage buyOrders = primeToBuyOrders[_prime];
        uint256 len = buyOrders.length;
        
        for (uint256 i=0; i<len; i++)
        {
            if (buyOrders[i].buyer == address(0x0) &&
                buyOrders[i].bid == 0)
            {
                return i;
            }
        }
        
        return len;
    }  

    function findHighestBidBuyOrder(uint256 _prime) public view returns (bool _found, uint256 _buyOrderIndex, address _buyer, uint256 _bid)
    {
        BuyOrder[] storage buyOrders = primeToBuyOrders[_prime];
        uint256 highestBidBuyOrderIndexFound = 0;
        uint256 highestBidFound = 0;
        address highestBidAddress = address(0x0);
        for (uint256 i=0; i<buyOrders.length; i++)
        {
            BuyOrder storage buyOrder = buyOrders[i];
            if (buyOrder.bid > highestBidFound &&
                addressToEtherBalance[buyOrder.buyer] >= buyOrder.bid)
            {
                highestBidBuyOrderIndexFound = i;
                highestBidFound = buyOrder.bid;
                highestBidAddress = buyOrder.buyer;
            }
        }
        if (highestBidFound == 0)
        {
            return (false, 0, address(0x0), 0);
        }
        else
        {
            return (true, highestBidBuyOrderIndexFound, highestBidAddress, highestBidFound);
        }
    }
    
    function findBuyOrdersOfUserOnPrime(address _user, uint256 _prime) external view returns (uint256[] memory _buyOrderIndices, uint256[] memory _bids)
    {
        BuyOrder[] storage buyOrders = primeToBuyOrders[_prime];
        
        _buyOrderIndices = new uint256[](buyOrders.length);
        _bids = new uint256[](buyOrders.length);
        
        uint256 amountOfBuyOrdersFound = 0;

        for (uint256 i=0; i<buyOrders.length; i++)
        {
            BuyOrder storage buyOrder = buyOrders[i];
            if (buyOrder.buyer == _user)
            {
                _buyOrderIndices[amountOfBuyOrdersFound] = i;
                _bids[amountOfBuyOrdersFound] = buyOrder.bid;
                amountOfBuyOrdersFound++;
            }
        }
        
        assembly
        {
             
            mstore(_buyOrderIndices, amountOfBuyOrdersFound)
            
             
            mstore(_bids, amountOfBuyOrdersFound)
        }
    }
    
    function findBuyOrdersOnUsersPrimes(address _user) external view returns (uint256[] memory _primes, uint256[] memory _buyOrderIndices, address[] memory _buyers, uint256[] memory _bids, bool[] memory _buyersHaveEnoughFunds)
    {
        uint256[] storage userPrimes = ownerToPrimes[_user];
        
        _primes = new uint256[](userPrimes.length);
        _buyOrderIndices = new uint256[](userPrimes.length);
        _buyers = new address[](userPrimes.length);
        _bids = new uint256[](userPrimes.length);
        _buyersHaveEnoughFunds = new bool[](userPrimes.length);
        
        uint256 amountOfBuyOrdersFound = 0;

        for (uint256 i=0; i<userPrimes.length; i++)
        {
            uint256 prime = userPrimes[i];
            
            bool found; uint256 buyOrderIndex; address buyer; uint256 bid;
            (found, buyOrderIndex, buyer, bid) = findHighestBidBuyOrder(prime);
            
            if (found == true)
            {
                _primes[amountOfBuyOrdersFound] = prime;
                _buyers[amountOfBuyOrdersFound] = buyer;
                _buyOrderIndices[amountOfBuyOrdersFound] = buyOrderIndex;
                _bids[amountOfBuyOrdersFound] = bid;
                _buyersHaveEnoughFunds[amountOfBuyOrdersFound] = addressToEtherBalance[buyer] >= bid;
                amountOfBuyOrdersFound++;
            }
        }
        
        assembly
        {
             
            mstore(_primes, amountOfBuyOrdersFound)
            
             
            mstore(_buyOrderIndices, amountOfBuyOrdersFound)
            
             
            mstore(_buyers, amountOfBuyOrdersFound)
            
             
            mstore(_bids, amountOfBuyOrdersFound)
            
             
            mstore(_buyersHaveEnoughFunds, amountOfBuyOrdersFound)
        }
    }
    
    
    
    
    
    
    
    
     
     
     
     
     
     
     
    
     
     
     
    
     
    
     
    
    function tryCancelBuyOrdersAndWithdrawEther(uint256[] calldata _primes, uint256[] calldata _buyOrderIndices, uint256 _amountToWithdraw) external returns (uint256 _amountCancelled)
    {
        withdrawEther(_amountToWithdraw);
        return tryCancelBuyOrders(_primes, _buyOrderIndices);
    }
}

contract EtherPrimeChat
{
    EtherPrime etherPrime;
    
    constructor(EtherPrime _etherPrime) public
    {
        etherPrime = _etherPrime;
    }
    
     
    mapping(address => bytes32) public addressToUsername;
    mapping(bytes32 => address) public usernameToAddress;
    mapping(address => uint256) public addressToGasUsedTowardsChatMessage;
    uint256 public constant GAS_PER_CHAT_MESSAGE = 1000000;
    address[] public chatMessageSenders;
    uint256[] public chatMessageReplyToIndices;
    string[] public chatMessages;
    
    event UsernameSet(address user, bytes32 username);
    event ChatMessageSent(address indexed sender, uint256 indexed index, uint256 indexed replyToIndex);
    
    function setUsername(bytes32 _username) external
    {
        require(_username[0] != 0x00);
        
        bool seen0x00 = false;
        for (uint256 i=0; i<32; i++)
        {
            if (_username[i] == 0x00)
            {
                seen0x00 = true;
            }
            
             
            else if (seen0x00)
            {
                revert("setUsername error: invalid string; character present after null terminator");
            }
        }
        
        require(usernameToAddress[_username] == address(0x0), "setUsername error: that username already exists");
        
        usernameToAddress[_username] = msg.sender;
        addressToUsername[msg.sender] = _username;
        
        emit UsernameSet(msg.sender, _username);
    }
    
    function amountOfChatMessages() external view returns (uint256)
    {
        return chatMessages.length;
    }
    
    function getChatMessage(uint256 _index) external view returns (address _sender, string memory _message, uint256 _replyToIndex)
    {
        require(_index < chatMessages.length, "getChatMessage error: index out of bounds");
        
        _sender = chatMessageSenders[_index];
        _message = chatMessages[_index];
        _replyToIndex = chatMessageReplyToIndices[_replyToIndex];
    }
    
    function sendChatMessage(string calldata _message, uint256 _replyToIndex) external
    {
        require(etherPrime.addressToGasSpent(msg.sender) - addressToGasUsedTowardsChatMessage[msg.sender] >= GAS_PER_CHAT_MESSAGE, "sendChatMessage error: you need to spend more gas on compute() to send a chat message");
        require(_replyToIndex == ~uint256(0) || _replyToIndex < chatMessages.length, "sendChatMessage error: invalid reply index");
        
        addressToGasUsedTowardsChatMessage[msg.sender] += GAS_PER_CHAT_MESSAGE;
        
        emit ChatMessageSent(msg.sender, chatMessages.length, _replyToIndex);
        
        chatMessageReplyToIndices.push(_replyToIndex);
        chatMessageSenders.push(msg.sender);
        chatMessages.push(_message);
    }
}