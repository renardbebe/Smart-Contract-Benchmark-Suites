 

pragma solidity ^0.4.11;

interface CommonWallet {
    function receive() external payable;
}

library StringUtils {
    function concat(string _a, string _b)
        internal
        pure
        returns (string)
    {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);

        bytes memory bab = new bytes(_ba.length + _bb.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }
}

library UintStringUtils {
    function toString(uint i)
        internal
        pure
        returns (string)
    {
        if (i == 0) return '0';
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
}

 
 
library AddressUtils {
     
     
     
     
     
    function isContract(address addr)
        internal
        view
        returns(bool)
    {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

  
  
library SafeMath256 {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

library SafeMath32 {
   
  function mul(uint32 a, uint32 b) internal pure returns (uint32 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }


   
  function div(uint32 a, uint32 b) internal pure returns (uint32) {
     
     
     
    return a / b;
  }


   
  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }


   
  function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

library SafeMath8 {
   
  function mul(uint8 a, uint8 b) internal pure returns (uint8 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }


   
  function div(uint8 a, uint8 b) internal pure returns (uint8) {
     
     
     
    return a / b;
  }


   
  function sub(uint8 a, uint8 b) internal pure returns (uint8) {
    assert(b <= a);
    return a - b;
  }


   
  function add(uint8 a, uint8 b) internal pure returns (uint8 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract DragonAccessControl 
{
     
    address constant NA = address(0);

     
    address internal controller_;

     
    enum Mode {TEST, PRESALE, OPERATE}

     
    Mode internal mode_ = Mode.TEST;

     
     
    mapping(address => bool) internal minions_;
    
     
    address internal presale_;

     
     
    modifier controllerOnly() {
        require(controller_ == msg.sender, "controller_only");
        _;
    }

     
    modifier minionOnly() {
        require(minions_[msg.sender], "minion_only");
        _;
    }

     
    modifier testModeOnly {
        require(mode_ == Mode.TEST, "test_mode_only");
        _;
    }

     
    modifier presaleModeOnly {
        require(mode_ == Mode.PRESALE, "presale_mode_only");
        _;
    }

     
    modifier operateModeOnly {
        require(mode_ == Mode.OPERATE, "operate_mode_only");
        _;
    }

      
    modifier presaleOnly() {
        require(msg.sender == presale_, "presale_only");
        _;
    }

     
    function setOperateMode()
        external 
        controllerOnly
        presaleModeOnly
    {
        mode_ = Mode.OPERATE;
    }

     
     
    function setPresale(address _presale)
        external
        controllerOnly
    {
        presale_ = _presale;
    }

     
    function setPresaleMode()
        external
        controllerOnly
        testModeOnly
    {
        mode_ = Mode.PRESALE;
    }    

         
     
    function controller()
        external
        view
        returns(address)
    {
        return controller_;
    }

     
     
     
     
    function setController(address _to)
        external
        controllerOnly
    {
        require(_to != NA, "_to");
        require(controller_ != _to, "already_controller");

        controller_ = _to;
    }

     
     
     
    function isMinion(address _addr)
        public view returns(bool)
    {
        return minions_[_addr];
    }   

    function getCurrentMode() 
        public view returns (Mode) 
    {
        return mode_;
    }    
}

 
contract DragonBase is DragonAccessControl
{
    using SafeMath8 for uint8;
    using SafeMath32 for uint32;
    using SafeMath256 for uint256;
    using StringUtils for string;
    using UintStringUtils for uint;    

     
    event Birth(address owner, uint256 petId, uint256 tokenId, uint256 parentA, uint256 parentB, string genes, string params);

     
    string internal name_;
     
    string internal symbol_;
     
    string internal url_;

    struct DragonToken {
         
        uint8   genNum;   
        string  genome;   
        uint256 petId;    

         
        uint256 parentA;
        uint256 parentB;

         
        string  params;   

         
        address owner; 
    }

     
    uint256 internal mintCount_;
     
    uint256 internal maxSupply_;
      
    uint256 internal burnCount_;

     
     
    mapping(uint256 => address) internal approvals_;
     
    mapping(address => mapping(address => bool)) internal operatorApprovals_;
     
    mapping(uint256 => uint256) internal ownerIndex_;
     
    mapping(address => uint256[]) internal ownTokens_;
     
    mapping(uint256 => DragonToken) internal tokens_;

     
    address constant NA = address(0);

     
     
     
    function _addTo(address _to, uint256 _tokenId)
        internal
    {
        DragonToken storage token = tokens_[_tokenId];
        require(token.owner == NA, "taken");

        uint256 lastIndex = ownTokens_[_to].length;
        ownTokens_[_to].push(_tokenId);
        ownerIndex_[_tokenId] = lastIndex;

        token.owner = _to;
    }

     
     
     
     
     
     
    function _createToken(
        address _to,
        
         
        uint8   _genNum,
        string   _genome,
        uint256 _parentA,
        uint256 _parentB,
        
         
        uint256 _petId,
        string   _params        
    )
        internal returns(uint256)
    {
        uint256 tokenId = mintCount_.add(1);
        mintCount_ = tokenId;

        DragonToken memory token = DragonToken(
            _genNum,
            _genome,
            _petId,

            _parentA,
            _parentB,

            _params,
            NA
        );
        
        tokens_[tokenId] = token;
        
        _addTo(_to, tokenId);
        
        emit Birth(_to, _petId, tokenId, _parentA, _parentB, _genome, _params);
        
        return tokenId;
    }    
 
     
     
     
    function getGenome(uint256 _tokenId)
        external view returns(string)
    {
        return tokens_[_tokenId].genome;
    }

     
     
     
    function getParams(uint256 _tokenId)
        external view returns(string)
    {
        return tokens_[_tokenId].params;
    }

     
     
     
    function getParentA(uint256 _tokenId)
        external view returns(uint256)
    {
        return tokens_[_tokenId].parentA;
    }   

     
     
     
    function getParentB(uint256 _tokenId)
        external view returns(uint256)
    {
        return tokens_[_tokenId].parentB;
    }

     
     
     
    function isExisting(uint256 _tokenId)
        public view returns(bool)
    {
        return tokens_[_tokenId].owner != NA;
    }    

     
     
    function maxSupply()
        external view returns(uint256)
    {
        return maxSupply_;
    }

     
     
    function setUrl(string _url)
        external controllerOnly
    {
        url_ = _url;
    }

     
     
    function symbol()
        external view returns(string)
    {
        return symbol_;
    }

     
     
     
    function tokenURI(uint256 _tokenId)
        external view returns(string)
    {
        return url_.concat(_tokenId.toString());
    }

      
     
    function name()
        external view returns(string)
    {
        return name_;
    }

     
    function getTokens(address _owner)
        external view  returns (uint256[], uint256[], byte[]) 
    {
        uint256[] memory tokens = ownTokens_[_owner];
        uint256[] memory tokenIds = new uint256[](tokens.length);
        uint256[] memory petIds = new uint256[](tokens.length);

        byte[] memory genomes = new byte[](tokens.length * 77);
        uint index = 0;

        for(uint i = 0; i < tokens.length; i++) {
            uint256 tokenId = tokens[i];
            
            DragonToken storage token = tokens_[tokenId];

            tokenIds[i] = tokenId;
            petIds[i] = token.petId;
            
            bytes storage genome = bytes(token.genome);
            
            for(uint j = 0; j < genome.length; j++) {
                genomes[index++] = genome[j];
            }
        }
        return (tokenIds, petIds, genomes);
    }
    
}

 
 

contract ERC721Basic 
{
     
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
     
    event Deposit(address indexed _sender, uint256 _value);
     
    event Withdraw(address indexed _sender, uint256 _value);
     
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

     
    function balanceOf(address _owner) external view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function exists(uint256 _tokenId) public view returns (bool _exists);
    
    function approve(address _to, uint256 _tokenId) external;
    function getApproved(uint256 _tokenId) public view returns (address _to);

     
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

    function totalSupply() public view returns (uint256 total);

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

 
contract ERC721Metadata is ERC721Basic 
{
    function name() external view returns (string _name);
    function symbol() external view returns (string _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string);
}


 
contract ERC721Receiver 
{
   
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
    function onERC721Received(address _from, uint256 _tokenId, bytes _data )
        public returns(bytes4);
}

 
contract ERC721 is ERC721Basic, ERC721Metadata, ERC721Receiver 
{
     
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

    bytes4 constant InterfaceSignature_ERC165 = 0x01ffc9a7;
     

    bytes4 constant InterfaceSignature_ERC721Enumerable = 0x780e9d63;
     

    bytes4 constant InterfaceSignature_ERC721Metadata = 0x5b5e139f;
     

    bytes4 constant InterfaceSignature_ERC721 = 0x80ac58cd;
     

    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165)
            || (_interfaceID == InterfaceSignature_ERC721)
            || (_interfaceID == InterfaceSignature_ERC721Enumerable)
            || (_interfaceID == InterfaceSignature_ERC721Metadata));
    }    
}

 
contract DragonOwnership is ERC721, DragonBase
{
    using StringUtils for string;
    using UintStringUtils for uint;    
    using AddressUtils for address;

     
     
    event TransferInfo(address indexed _from, address indexed _to, uint256 _tokenId, uint256 petId, string genes, string params);

     
     
     
     
     
    function isOwnerOrApproved(uint256 _tokenId, address _addr)
        public view returns(bool)
    {
        DragonToken memory token = tokens_[_tokenId];

        if (token.owner == _addr) {
            return true;
        }
        else if (isApprovedFor(_tokenId, _addr)) {
            return true;
        }
        else if (isApprovedForAll(token.owner, _addr)) {
            return true;
        }

        return false;
    }

     
     
    modifier ownerOrApprovedOnly(uint256 _tokenId) {
        require(isOwnerOrApproved(_tokenId, msg.sender), "tokenOwnerOrApproved_only");
        _;
    }

     
     
    modifier ownOnly(uint256 _tokenId) {
        require(tokens_[_tokenId].owner == address(this), "own_only");
        _;
    }

     
     
     
     
    function isApprovedFor(uint256 _tokenId, address _approvee)
        public view returns(bool)
    {
        return approvals_[_tokenId] == _approvee;
    }

     
     
     
     
    function isApprovedForAll(address _owner, address _operator)
        public view returns(bool)
    {
        return operatorApprovals_[_owner][_operator];
    }

     
     
     
    function exists(uint256 _tokenId)
        public view returns(bool)
    {
        return tokens_[_tokenId].owner != NA;
    }

     
     
     
    function ownerOf(uint256 _tokenId)
        public view returns(address)
    {
        return tokens_[_tokenId].owner;
    }

     
     
     
    function getApproved(uint256 _tokenId)
        public view returns(address)
    {
        return approvals_[_tokenId];
    }

     
     
     
    function approve(address _to, uint256 _tokenId)
        external ownerOrApprovedOnly(_tokenId)
    {
        address owner = ownerOf(_tokenId);
        require(_to != owner);

        if (getApproved(_tokenId) != NA || _to != NA) {
            approvals_[_tokenId] = _to;

            emit Approval(owner, _to, _tokenId);
        }
    }

     
     
    function totalSupply()
        public view returns(uint256)
    {
        return mintCount_;
    }    

     
     
     
    function balanceOf(address _owner)
        external view returns(uint256)
    {
        return ownTokens_[_owner].length;
    }    

     
     
     
     
    function _setApprovalForAll(address _owner, address _to, bool _approved)
        internal
    {
        operatorApprovals_[_owner][_to] = _approved;

        emit ApprovalForAll(_owner, _to, _approved);
    }

     
     
     
    function setApprovalForAll(address _to, bool _approved)
        external
    {
        require(_to != msg.sender);

        _setApprovalForAll(msg.sender, _to, _approved);
    }

     
     
     
     
    function _clearApproval(address _from, uint256 _tokenId)
        internal
    {
        if (approvals_[_tokenId] == NA) {
            return;
        }

        approvals_[_tokenId] = NA;
        emit Approval(_from, NA, _tokenId);
    }

     
     
     
     
     
     
     
    function _checkAndCallSafeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        internal returns(bool)
    {
        if (! _to.isContract()) {
            return true;
        }

        bytes4 retval = ERC721Receiver(_to).onERC721Received(
            _from, _tokenId, _data
        );

        return (retval == ERC721_RECEIVED);
    }

     
     
    function _remove(uint256 _tokenId)
        internal
    {
        address owner = tokens_[_tokenId].owner;
        _removeFrom(owner, _tokenId);
    }

     
     
     
    function _removeFrom(address _owner, uint256 _tokenId)
        internal
    {
        uint256 lastIndex = ownTokens_[_owner].length.sub(1);
        uint256 lastToken = ownTokens_[_owner][lastIndex];

         
        ownTokens_[_owner][ownerIndex_[_tokenId]] = lastToken;
        ownTokens_[_owner].length--;

         
        ownerIndex_[lastToken] = ownerIndex_[_tokenId];
        ownerIndex_[_tokenId] = 0;

        DragonToken storage token = tokens_[_tokenId];
        token.owner = NA;
    }

     
     
     
     
     
    function transferFrom( address _from, address _to, uint256 _tokenId )
        public ownerOrApprovedOnly(_tokenId)
    {
        require(_from != NA);
        require(_to != NA);

        _clearApproval(_from, _tokenId);
        _removeFrom(_from, _tokenId);
        _addTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);

        DragonToken storage token = tokens_[_tokenId];
        emit TransferInfo(_from, _to, _tokenId, token.petId, token.genome, token.params);
    }

     
     
     
     
     
    function updateAndSafeTransferFrom(
        address _to,
        uint256 _tokenId,
        string _params
    )
        public
    {
        updateAndSafeTransferFrom(_to, _tokenId, _params, "");
    }

     
     
     
     
     
     
     
    function updateAndSafeTransferFrom(
        address _to,
        uint256 _tokenId,
        string _params,
        bytes _data
    )
        public
    {
         
        updateAndTransferFrom(_to, _tokenId, _params, 0, 0);
        require(_checkAndCallSafeTransfer(address(this), _to, _tokenId, _data));
    }

     
     
     
     
     
    function updateAndTransferFrom(
        address _to,
        uint256 _tokenId,
        string _params,
        uint256 _petId, 
        uint256 _transferCost
    )
        public
        ownOnly(_tokenId)
        minionOnly
    {
        require(bytes(_params).length > 0, "params_length");

         
        tokens_[_tokenId].params = _params;
        if (tokens_[_tokenId].petId == 0 ) {
            tokens_[_tokenId].petId = _petId;
        }

        address from = tokens_[_tokenId].owner;

         
        transferFrom(from, _to, _tokenId);

         
         
         
        if (_transferCost > 0) {
            msg.sender.transfer(_transferCost);
        }
    }

     
     
     
     
     
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
    {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

     
     
     
     
     
     
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        public
    {
        transferFrom(_from, _to, _tokenId);
        require(_checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }

     
     
     
    function burn(uint256 _tokenId)
        public
        ownerOrApprovedOnly(_tokenId)
    {
        address owner = tokens_[_tokenId].owner;
        _remove(_tokenId);

        burnCount_ += 1;

        emit Transfer(owner, NA, _tokenId);
    }

     
     
     
    function burnCount()
        external
        view
        returns(uint256)
    {
        return burnCount_;
    }

    function onERC721Received(address, uint256, bytes)
        public returns(bytes4) 
    {
        return ERC721_RECEIVED;
    }
}



 
 
contract EtherDragonsCore is DragonOwnership 
{
    using SafeMath8 for uint8;
    using SafeMath32 for uint32;
    using SafeMath256 for uint256;
    using AddressUtils for address;
    using StringUtils for string;
    using UintStringUtils for uint;

     
    address constant NA = address(0);

     
    uint256 public constant BOUNTY_LIMIT = 2500;
     
    uint256 public constant PRESALE_LIMIT = 7500;
     
    uint256 public constant GEN0_CREATION_LIMIT = 90000;
    
     
    uint256 internal presaleCount_;  
     
    uint256 internal bountyCount_;
   
     
    address internal bank_;

     

     
     
    function ()
        public payable
    {
        revert();
    }

     
     
    function getBalance() 
        public view returns (uint256)
    {
        return address(this).balance;
    }    

     
     
    constructor(
        address _bank
    )
        public
    {
        require(_bank != NA);
        
        controller_ = msg.sender;
        bank_ = _bank;
        
         
        name_ = "EtherDragons";
        symbol_ = "ED";
        url_ = "https://game.etherdragons.world/token/";

         
        maxSupply_ = GEN0_CREATION_LIMIT + BOUNTY_LIMIT + PRESALE_LIMIT;
    }

     
    function totalPresaleCount()
        public view returns(uint256)
    {
        return presaleCount_;
    }    

     
    function totalBountyCount()
        public view returns(uint256)
    {
        return bountyCount_;
    }    
    
     
     
     
     
    function canMint()
        public view returns(bool)
    {
        return (mintCount_ + presaleCount_ + bountyCount_) < maxSupply_;
    }

     
     
     
    function minionAdd(address _to)
        external controllerOnly
    {
        require(minions_[_to] == false, "already_minion");
        
         
         
        _setApprovalForAll(address(this), _to, true);
        
        minions_[_to] = true;
    }

     
     
    function minionRemove(address _to)
        external controllerOnly
    {
        require(minions_[_to], "not_a_minion");

         
        _setApprovalForAll(address(this), _to, false);
        minions_[_to] = false;
    }

     
     
     
    function depositTo()
        public payable
    {
        emit Deposit(msg.sender, msg.value);
    }    
    
     
     
     
     
     
    function transferAmount(address _to, uint256 _amount, uint256 _transferCost)
        external minionOnly
    {
        require((_amount + _transferCost) <= address(this).balance, "not enough money!");
        _to.transfer(_amount);

         
         
         
        if (_transferCost > 0) {
            msg.sender.transfer(_transferCost);
        }

        emit Withdraw(_to, _amount);
    }        

    
     
     
     
     
     
     
     
     
     
     
     
    function mintRelease(
        address _to,
        uint256 _fee,
        
         
        uint8   _genNum,
        string   _genome,
        uint256 _parentA,
        uint256 _parentB,
        
         
        uint256 _petId,   
        string   _params,
        uint256 _transferCost
    )
        external minionOnly operateModeOnly returns(uint256)
    {
        require(canMint(), "can_mint");
        require(_to != NA, "_to");
        require((_fee + _transferCost) <= address(this).balance, "_fee");
        require(bytes(_params).length != 0, "params_length");
        require(bytes(_genome).length == 77, "genome_length");
        
         
        if (_parentA != 0 && _parentB != 0) {
            require(_parentA != _parentB, "same_parent");
        }
        else if (_parentA == 0 && _parentB != 0) {
            revert("parentA_empty");
        }
        else if (_parentB == 0 && _parentA != 0) {
            revert("parentB_empty");
        }

        uint256 tokenId = _createToken(_to, _genNum, _genome, _parentA, _parentB, _petId, _params);

        require(_checkAndCallSafeTransfer(NA, _to, tokenId, ""), "safe_transfer");

         
        CommonWallet(bank_).receive.value(_fee)();

        emit Transfer(NA, _to, tokenId);

         
         
         
        if (_transferCost > 0) {
            msg.sender.transfer(_transferCost);
        }

        return tokenId;
    }

     
     
     
     
     
     
    function mintPresell(address _to, string _genome)
        external presaleOnly presaleModeOnly returns(uint256)
    {
        require(presaleCount_ < PRESALE_LIMIT, "presale_limit");

         
        uint256 tokenId = _createToken(_to, 0, _genome, 0, 0, 0, "");
        presaleCount_ += 1;

        require(_checkAndCallSafeTransfer(NA, _to, tokenId, ""), "safe_transfer");

        emit Transfer(NA, _to, tokenId);
        
        return tokenId;
    }    
    
     
     
     
    function mintBounty(address _to, string _genome)
        external controllerOnly returns(uint256)
    {
        require(bountyCount_ < BOUNTY_LIMIT, "bounty_limit");

         
        uint256 tokenId = _createToken(_to, 0, _genome, 0, 0, 0, "");
    
        bountyCount_ += 1;
        require(_checkAndCallSafeTransfer(NA, _to, tokenId, ""), "safe_transfer");

        emit Transfer(NA, _to, tokenId);

        return tokenId;
    }        
}