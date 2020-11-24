 

pragma solidity ^0.5.2;

contract IDFEngine {
    function disableOwnership() public;
    function transferOwnership(address newOwner_) public;
    function acceptOwnership() public;
    function setAuthority(address authority_) public;
    function deposit(address _sender, address _tokenID, uint _feeTokenIdx, uint _amount) public returns (uint);
    function withdraw(address _sender, address _tokenID, uint _feeTokenIdx, uint _amount) public returns (uint);
    function destroy(address _sender, uint _feeTokenIdx, uint _amount) public returns (bool);
    function claim(address _sender, uint _feeTokenIdx) public returns (uint);
    function oneClickMinting(address _sender, uint _feeTokenIdx, uint _amount) public;
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

contract DFUpgrader is DSAuth {

     
     
    IDFEngine public iDFEngine;

     
    address newDFEngine;

     
    constructor () public {
        iDFEngine = IDFEngine(0x0);
    }

     
     
     
    function requestImplChange(address _newDFEngine) public onlyOwner {
        require(_newDFEngine != address(0), "_newDFEngine: The address is empty");

        newDFEngine = _newDFEngine;

        emit ImplChangeRequested(msg.sender, _newDFEngine);
    }

     
    function confirmImplChange() public onlyOwner {
        iDFEngine = IDFEngine(newDFEngine);

        emit ImplChangeConfirmed(address(iDFEngine));
    }

     
    event ImplChangeRequested(address indexed _msgSender, address indexed _proposedImpl);

     
    event ImplChangeConfirmed(address indexed _newImpl);
}

contract DFProtocol is DFUpgrader {
     
     
     

     
    event Deposit (address indexed _tokenID, address indexed _sender, uint _tokenAmount, uint _usdxAmount);

     
    event Withdraw(address indexed _tokenID, address indexed _sender, uint _expectedAmount, uint _actualAmount);

     
    event Destroy (address indexed _sender, uint _usdxAmount);

     
    event Claim(address indexed _sender, uint _usdxAmount);

     
    event OneClickMinting(address indexed _sender, uint _usdxAmount);

     
     
     

     
    function deposit(address _tokenID, uint _feeTokenIdx, uint _tokenAmount) public returns (uint){
        uint _usdxAmount = iDFEngine.deposit(msg.sender, _tokenID, _feeTokenIdx, _tokenAmount);
        emit Deposit(_tokenID, msg.sender, _tokenAmount, _usdxAmount);
        return _usdxAmount;
    }

     
    function withdraw(address _tokenID, uint _feeTokenIdx, uint _expectedAmount) public returns (uint) {
        uint _actualAmount = iDFEngine.withdraw(msg.sender, _tokenID, _feeTokenIdx, _expectedAmount);
        emit Withdraw(_tokenID, msg.sender, _expectedAmount, _actualAmount);
        return _actualAmount;
    }

     
    function destroy(uint _feeTokenIdx, uint _usdxAmount) public {
        iDFEngine.destroy(msg.sender, _feeTokenIdx, _usdxAmount);
        emit Destroy(msg.sender, _usdxAmount);
    }

     
    function claim(uint _feeTokenIdx) public returns (uint) {
        uint _usdxAmount = iDFEngine.claim(msg.sender, _feeTokenIdx);
        emit Claim(msg.sender, _usdxAmount);
        return _usdxAmount;
    }

     
    function oneClickMinting(uint _feeTokenIdx, uint _usdxAmount) public {
        iDFEngine.oneClickMinting(msg.sender, _feeTokenIdx, _usdxAmount);
        emit OneClickMinting(msg.sender, _usdxAmount);
    }
}