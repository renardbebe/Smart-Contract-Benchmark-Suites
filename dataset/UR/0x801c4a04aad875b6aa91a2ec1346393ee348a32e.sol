 

pragma solidity ^0.5.2;

contract IDFStore {

    function getSectionMinted(uint _position) public view returns (uint);
    function addSectionMinted(uint _amount) public;
    function addSectionMinted(uint _position, uint _amount) public;
    function setSectionMinted(uint _amount) public;
    function setSectionMinted(uint _position, uint _amount) public;

    function getSectionBurned(uint _position) public view returns (uint);
    function addSectionBurned(uint _amount) public;
    function addSectionBurned(uint _position, uint _amount) public;
    function setSectionBurned(uint _amount) public;
    function setSectionBurned(uint _position, uint _amount) public;

    function getSectionToken(uint _position) public view returns (address[] memory);
    function getSectionWeight(uint _position) public view returns (uint[] memory);
    function getSectionData(uint _position) public view returns (uint, uint, uint, address[] memory, uint[] memory);
    function getBackupSectionData(uint _position) public view returns (uint, address[] memory, uint[] memory);
    function getBackupSectionIndex(uint _position) public view returns (uint);
    function setBackupSectionIndex(uint _position, uint _backupIdx) public;

    function setSection(address[] memory _wrappedTokens, uint[] memory _weight) public;
    function setBackupSection(uint _position, address[] memory _tokens, uint[] memory _weight) public;
    function burnSectionMoveon() public;

    function getMintingToken(address _token) public view returns (bool);
    function setMintingToken(address _token, bool _flag) public;
    function getMintedToken(address _token) public view returns (bool);
    function setMintedToken(address _token, bool _flag) public;
    function getBackupToken(address _token) public view returns (address);
    function setBackupToken(address _token, address _backupToken) public;
    function getMintedTokenList() public view returns (address[] memory);

    function getMintPosition() public view returns (uint);
    function getBurnPosition() public view returns (uint);

    function getTotalMinted() public view returns (uint);
    function addTotalMinted(uint _amount) public;
    function setTotalMinted(uint _amount) public;
    function getTotalBurned() public view returns (uint);
    function addTotalBurned(uint _amount) public;
    function setTotalBurned(uint _amount) public;
    function getMinBurnAmount() public view returns (uint);
    function setMinBurnAmount(uint _amount) public;

    function getTokenBalance(address _tokenID) public view returns (uint);
    function setTokenBalance(address _tokenID, uint _amount) public;
    function getResUSDXBalance(address _tokenID) public view returns (uint);
    function setResUSDXBalance(address _tokenID, uint _amount) public;
    function getDepositorBalance(address _depositor, address _tokenID) public view returns (uint);
    function setDepositorBalance(address _depositor, address _tokenID, uint _amount) public;

    function getFeeRate(uint ct) public view returns (uint);
    function setFeeRate(uint ct, uint rate) public;
    function getTypeToken(uint tt) public view returns (address);
    function setTypeToken(uint tt, address _tokenID) public;
    function getTokenMedian(address _tokenID) public view returns (address);
    function setTokenMedian(address _tokenID, address _median) public;

    function setTotalCol(uint _amount) public;
    function getTotalCol() public view returns (uint);

    function setWrappedToken(address _srcToken, address _wrappedToken) public;
    function getWrappedToken(address _srcToken) public view returns (address);
}

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
    event OwnerUpdate     (address indexed owner, address indexed newOwner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;
    address      public  newOwner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

     
    function disableOwnership() public onlyOwner {
        owner = address(0);
        emit OwnerUpdate(msg.sender, owner);
    }

    function transferOwnership(address newOwner_) public onlyOwner {
        require(newOwner_ != owner, "TransferOwnership: the same owner.");
        newOwner = newOwner_;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner, "AcceptOwnership: only new owner do this.");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0x0);
    }

     
    function setAuthority(DSAuthority authority_)
        public
        onlyOwner
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier onlyOwner {
        require(isOwner(msg.sender), "ds-auth-non-owner");
        _;
    }

    function isOwner(address src) internal view returns (bool) {
        return bool(src == owner);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

contract DFSetting is DSAuth {
    IDFStore public dfStore;

    enum ProcessType {
        CT_DEPOSIT,
        CT_DESTROY,
        CT_CLAIM,
        CT_WITHDRAW
    }

    enum TokenType {
        TT_DF,
        TT_USDX
    }

    constructor (address _dfStore) public {
        dfStore = IDFStore(_dfStore);
    }

     
    function setCommissionRate(ProcessType ct, uint rate) public auth {
        dfStore.setFeeRate(uint(ct), rate);
    }

     
    function setCommissionToken(TokenType ft, address _tokenID) public auth {
        dfStore.setTypeToken(uint(ft), _tokenID);
    }

     
    function setCommissionMedian(address _tokenID, address _median) public auth {
        dfStore.setTokenMedian(_tokenID, _median);
    }

     
    function setDestroyThreshold(uint _amount) public auth {
        dfStore.setMinBurnAmount(_amount);
    }

     
    function updateMintSection(address[] memory _wrappedTokens, uint[] memory _weight) public auth {
        dfStore.setSection(_wrappedTokens, _weight);
    }
}