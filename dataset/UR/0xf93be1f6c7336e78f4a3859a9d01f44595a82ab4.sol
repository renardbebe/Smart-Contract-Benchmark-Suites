 

pragma solidity ^0.4.23;

pragma solidity ^0.4.23;

pragma solidity ^0.4.23;

 
contract ERC20 {

     
     

    string public symbol;
    string public  name;
    uint8 public decimals;

    function transfer(address _to, uint _value, bytes _data) external returns (bool success);

     
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);

     
     


    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

     
    function transferBulk(address[] to, uint[] tokens) public;
    function approveBulk(address[] spender, uint[] tokens) public;
}

pragma solidity ^0.4.23;

 
 
 
interface ERC721   {

     
     
     
     
     
     
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

     
     
     
     
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

     
     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
     
     
     
     
    function balanceOf(address _owner) external view returns (uint256);

     
     
     
     
     
    function ownerOf(uint256 _tokenId) external view returns (address);

     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;
    
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

     
     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
     
     
     
     
     
    function approve(address _approved, uint256 _tokenId) external;

     
     
     
     
     
    function setApprovalForAll(address _operator, bool _approved) external;

     
     
     
     
    function getApproved(uint256 _tokenId) external view returns (address);

     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);


    
    function name() external pure returns (string _name);

     
    function symbol() external pure returns (string _symbol);

    
     
     
     
     
    function tokenURI(uint256 _tokenId) external view returns (string);

      
     
     
    function totalSupply() external view returns (uint256);

     
     
     
     
     
    function tokenByIndex(uint256 _index) external view returns (uint256);

     
     
     
     
     
     
     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);

     
     
     
     
     
    function transfer(address _to, uint256 _cutieId) external;
}

pragma solidity ^0.4.23;

pragma solidity ^0.4.23;


 
interface ERC165 {

     
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}


 
interface IERC1155   {
     
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

     
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
    event URI(string _value, uint256 indexed _id);

     
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes _data) external;

     
    function safeBatchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values, bytes _data) external;

     
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

     
    function balanceOfBatch(address[] _owners, uint256[] _ids) external view returns (uint256[] memory);

     
    function setApprovalForAll(address _operator, bool _approved) external;

     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


contract Operators
{
    mapping (address=>bool) ownerAddress;
    mapping (address=>bool) operatorAddress;

    constructor() public
    {
        ownerAddress[msg.sender] = true;
    }

    modifier onlyOwner()
    {
        require(ownerAddress[msg.sender]);
        _;
    }

    function isOwner(address _addr) public view returns (bool) {
        return ownerAddress[_addr];
    }

    function addOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));

        ownerAddress[_newOwner] = true;
    }

    function removeOwner(address _oldOwner) external onlyOwner {
        delete(ownerAddress[_oldOwner]);
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender));
        _;
    }

    function isOperator(address _addr) public view returns (bool) {
        return operatorAddress[_addr] || ownerAddress[_addr];
    }

    function addOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0));

        operatorAddress[_newOperator] = true;
    }

    function removeOperator(address _oldOperator) external onlyOwner {
        delete(operatorAddress[_oldOperator]);
    }

    function withdrawERC20(ERC20 _tokenContract) external onlyOwner
    {
        uint256 balance = _tokenContract.balanceOf(address(this));
        _tokenContract.transfer(msg.sender, balance);
    }

    function approveERC721(ERC721 _tokenContract) external onlyOwner
    {
        _tokenContract.setApprovalForAll(msg.sender, true);
    }

    function approveERC1155(IERC1155 _tokenContract) external onlyOwner
    {
        _tokenContract.setApprovalForAll(msg.sender, true);
    }

    function withdrawEth() external onlyOwner
    {
        if (address(this).balance > 0)
        {
            msg.sender.transfer(address(this).balance);
        }
    }
}

pragma solidity ^0.4.23;

 
contract PluginInterface
{
     
    function isPluginInterface() public pure returns (bool);

    function onRemove() public;

     
     
     
     
    function run(
        uint40 _cutieId,
        uint256 _parameter,
        address _seller
    )
    public
    payable;

     
     
     
    function runSigned(
        uint40 _cutieId,
        uint256 _parameter,
        address _owner
    ) external payable;

    function withdraw() external;
}

pragma solidity ^0.4.23;

interface PluginsInterface
{
    function isPlugin(address contractAddress) external view returns(bool);
    function withdraw() external;
    function setMinSign(uint40 _newMinSignId) external;

    function runPluginOperator(
        address _pluginAddress,
        uint40 _signId,
        uint40 _cutieId,
        uint128 _value,
        uint256 _parameter,
        address _sender) external payable;
}

pragma solidity ^0.4.23;

pragma solidity ^0.4.23;

 
 
 
interface ConfigInterface
{
    function isConfig() external pure returns (bool);

    function getCooldownIndexFromGeneration(uint16 _generation, uint40 _cutieId) external view returns (uint16);
    function getCooldownEndTimeFromIndex(uint16 _cooldownIndex, uint40 _cutieId) external view returns (uint40);
    function getCooldownIndexFromGeneration(uint16 _generation) external view returns (uint16);
    function getCooldownEndTimeFromIndex(uint16 _cooldownIndex) external view returns (uint40);

    function getCooldownIndexCount() external view returns (uint256);

    function getBabyGenFromId(uint40 _momId, uint40 _dadId) external view returns (uint16);
    function getBabyGen(uint16 _momGen, uint16 _dadGen) external pure returns (uint16);

    function getTutorialBabyGen(uint16 _dadGen) external pure returns (uint16);

    function getBreedingFee(uint40 _momId, uint40 _dadId) external view returns (uint256);
}


contract CutieCoreInterface
{
    function isCutieCore() pure public returns (bool);

    ConfigInterface public config;

    function transferFrom(address _from, address _to, uint256 _cutieId) external;
    function transfer(address _to, uint256 _cutieId) external;

    function ownerOf(uint256 _cutieId)
        external
        view
        returns (address owner);

    function getCutie(uint40 _id)
        external
        view
        returns (
        uint256 genes,
        uint40 birthTime,
        uint40 cooldownEndTime,
        uint40 momId,
        uint40 dadId,
        uint16 cooldownIndex,
        uint16 generation
    );

    function getGenes(uint40 _id)
        public
        view
        returns (
        uint256 genes
    );


    function getCooldownEndTime(uint40 _id)
        public
        view
        returns (
        uint40 cooldownEndTime
    );

    function getCooldownIndex(uint40 _id)
        public
        view
        returns (
        uint16 cooldownIndex
    );


    function getGeneration(uint40 _id)
        public
        view
        returns (
        uint16 generation
    );

    function getOptional(uint40 _id)
        public
        view
        returns (
        uint64 optional
    );


    function changeGenes(
        uint40 _cutieId,
        uint256 _genes)
        public;

    function changeCooldownEndTime(
        uint40 _cutieId,
        uint40 _cooldownEndTime)
        public;

    function changeCooldownIndex(
        uint40 _cutieId,
        uint16 _cooldownIndex)
        public;

    function changeOptional(
        uint40 _cutieId,
        uint64 _optional)
        public;

    function changeGeneration(
        uint40 _cutieId,
        uint16 _generation)
        public;

    function createSaleAuction(
        uint40 _cutieId,
        uint128 _startPrice,
        uint128 _endPrice,
        uint40 _duration
    )
    public;

    function getApproved(uint256 _tokenId) external returns (address);
    function totalSupply() view external returns (uint256);
    function createPromoCutie(uint256 _genes, address _owner) external;
    function checkOwnerAndApprove(address _claimant, uint40 _cutieId, address _pluginsContract) external view;
    function breedWith(uint40 _momId, uint40 _dadId) public payable returns (uint40);
    function getBreedingFee(uint40 _momId, uint40 _dadId) public view returns (uint256);
    function restoreCutieToAddress(uint40 _cutieId, address _recipient) external;
    function createGen0Auction(uint256 _genes, uint128 startPrice, uint128 endPrice, uint40 duration) external;
    function createGen0AuctionWithTokens(uint256 _genes, uint128 startPrice, uint128 endPrice, uint40 duration, address[] allowedTokens) external;
    function createPromoCutieWithGeneration(uint256 _genes, address _owner, uint16 _generation) external;
    function createPromoCutieBulk(uint256[] _genes, address _owner, uint16 _generation) external;
}


contract Plugins is Operators, PluginsInterface
{
    event SignUsed(uint40 signId, address sender);
    event MinSignSet(uint40 signId);

    uint40 public minSignId;
    mapping(uint40 => address) public usedSignes;
    address public signerAddress;

    mapping(address => PluginInterface) public plugins;
    PluginInterface[] public pluginsArray;
    CutieCoreInterface public coreContract;

    function setSigner(address _newSigner) external onlyOwner {
        signerAddress = _newSigner;
    }

     
     
    function addPlugin(address _address) external onlyOwner
    {
        PluginInterface candidateContract = PluginInterface(_address);

         
        require(candidateContract.isPluginInterface());

         
        plugins[_address] = candidateContract;
        pluginsArray.push(candidateContract);
    }

     
    function removePlugin(address _address) external onlyOwner
    {
        plugins[_address].onRemove();
        delete plugins[_address];

        uint256 kindex = 0;
        while (kindex < pluginsArray.length)
        {
            if (address(pluginsArray[kindex]) == _address)
            {
                pluginsArray[kindex] = pluginsArray[pluginsArray.length-1];
                pluginsArray.length--;
            }
            else
            {
                kindex++;
            }
        }
    }

     
    function hashArguments(
        address _pluginAddress,
        uint40 _signId,
        uint40 _cutieId,
        uint128 _value,
        uint256 _parameter)
    public pure returns (bytes32 msgHash)
    {
        msgHash = keccak256(abi.encode(_pluginAddress, _signId, _cutieId, _value, _parameter));
    }

     
    function getSigner(
        address _pluginAddress,
        uint40 _signId,
        uint40 _cutieId,
        uint128 _value,
        uint256 _parameter,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
    public pure returns (address)
    {
        bytes32 msgHash = hashArguments(_pluginAddress, _signId, _cutieId, _value, _parameter);
        return ecrecover(msgHash, _v, _r, _s);
    }

     
    function isValidSignature(
        address _pluginAddress,
        uint40 _signId,
        uint40 _cutieId,
        uint128 _value,
        uint256 _parameter,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
    public
    view
    returns (bool)
    {
        return getSigner(_pluginAddress, _signId, _cutieId, _value, _parameter, _v, _r, _s) == signerAddress;
    }

     
     
     
    function runPluginSigned(
        address _pluginAddress,
        uint40 _signId,
        uint40 _cutieId,
        uint128 _value,
        uint256 _parameter,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
 
        payable
    {
        require (isValidSignature(_pluginAddress, _signId, _cutieId, _value, _parameter, _v, _r, _s));

        require(address(plugins[_pluginAddress]) != address(0));

        require (usedSignes[_signId] == address(0));

        require (_signId >= minSignId);
         

        require (_value <= msg.value);

        usedSignes[_signId] = msg.sender;

        if (_cutieId > 0)
        {
             
             
             

            require(coreContract.ownerOf(_cutieId) == msg.sender);
        }

        emit SignUsed(_signId, msg.sender);

         
         
        plugins[_pluginAddress].runSigned.value(_value)(
            _cutieId,
            _parameter,
            msg.sender
        );
    }

     
     
     
    function runPluginOperator(
        address _pluginAddress,
        uint40 _signId,
        uint40 _cutieId,
        uint128 _value,
        uint256 _parameter,
        address _sender)
        external payable onlyOperator
    {
        require(address(plugins[_pluginAddress]) != address(0));

        require (usedSignes[_signId] == address(0));

        require (_signId >= minSignId);
         


        require (_value <= msg.value);

        usedSignes[_signId] = _sender;

        emit SignUsed(_signId, _sender);


         
         
        plugins[_pluginAddress].runSigned.value(_value)(
            _cutieId,
            _parameter,
            _sender
        );
    }

    function setSignAsUsed(uint40 _signId, address _sender) external onlyOperator
    {
        usedSignes[_signId] = _sender;
        emit SignUsed(_signId, _sender);
    }

     
     
     
    function setMinSign(uint40 _newMinSignId) external onlyOperator
    {
        require (_newMinSignId > minSignId);
        minSignId = _newMinSignId;
        emit MinSignSet(minSignId);
    }

     
    function runPlugin(
        address _pluginAddress,
        uint40 _cutieId,
        uint256 _parameter
    ) external payable
    {
         
         
         
        require(address(plugins[_pluginAddress]) != address(0));
        if (_cutieId > 0)
        {
            coreContract.checkOwnerAndApprove(msg.sender, _cutieId, _pluginAddress);
        }

         
         
        plugins[_pluginAddress].run.value(msg.value)(
            _cutieId,
            _parameter,
            msg.sender
        );
    }

    function isPlugin(address contractAddress) external view returns(bool)
    {
        return address(plugins[contractAddress]) != address(0);
    }

    function setup(address _address) external onlyOwner
    {
        coreContract = CutieCoreInterface(_address);
    }

    function withdraw() external
    {
        require(
            msg.sender == address(coreContract) ||
            isOwner(msg.sender)
        );
        for (uint32 i = 0; i < pluginsArray.length; ++i)
        {
            pluginsArray[i].withdraw();
        }
    }
}