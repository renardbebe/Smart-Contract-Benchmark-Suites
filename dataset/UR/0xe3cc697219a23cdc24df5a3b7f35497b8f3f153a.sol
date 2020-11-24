 

pragma solidity ^0.4.18;

 
interface IOwnership {

     
    function isOwner(address _account) public view returns (bool);


     
    function getOwner() public view returns (address);
}


 
contract Ownership is IOwnership {

     
    address internal owner;


     
    modifier only_owner() {
        require(msg.sender == owner);
        _;
    }


     
    function Ownership() public {
        owner = msg.sender;
    }


     
    function isOwner(address _account) public view returns (bool) {
        return _account == owner;
    }


     
    function getOwner() public view returns (address) {
        return owner;
    }
}


 
interface ITransferableOwnership {
    

     
    function transferOwnership(address _newOwner) public;
}



 
contract TransferableOwnership is ITransferableOwnership, Ownership {


     
    function transferOwnership(address _newOwner) public only_owner {
        owner = _newOwner;
    }
}


 
interface IAuthenticator {
    

     
    function authenticate(address _account) public view returns (bool);
}


 
interface IAuthenticationManager {
    

     
    function isAuthenticating() public view returns (bool);


     
    function enableAuthentication() public;


     
    function disableAuthentication() public;
}


 
interface IToken { 

     
    function totalSupply() public view returns (uint);


     
    function balanceOf(address _owner) public view returns (uint);


     
    function transfer(address _to, uint _value) public returns (bool);


     
    function transferFrom(address _from, address _to, uint _value) public returns (bool);


     
    function approve(address _spender, uint _value) public returns (bool);


     
    function allowance(address _owner, address _spender) public view returns (uint);
}


 
interface IManagedToken { 

     
    function isLocked() public view returns (bool);


     
    function lock() public returns (bool);


     
    function unlock() public returns (bool);


     
    function issue(address _to, uint _value) public returns (bool);


     
    function burn(address _from, uint _value) public returns (bool);
}


 
interface ITokenRetriever {

     
    function retrieveTokens(address _tokenContract) public;
}


 
contract TokenRetriever is ITokenRetriever {

     
    function retrieveTokens(address _tokenContract) public {
        IToken tokenInstance = IToken(_tokenContract);
        uint tokenBalance = tokenInstance.balanceOf(this);
        if (tokenBalance > 0) {
            tokenInstance.transfer(msg.sender, tokenBalance);
        }
    }
}


 
interface ITokenObserver {


     
    function notifyTokensReceived(address _from, uint _value) public;
}


 
contract TokenObserver is ITokenObserver {


     
    function notifyTokensReceived(address _from, uint _value) public {
        onTokensReceived(msg.sender, _from, _value);
    }


     
    function onTokensReceived(address _token, address _from, uint _value) internal;
}


 
interface IPausable {


     
    function isPaused() public view returns (bool);


     
    function pause() public;


     
    function resume() public;
}


 
interface ITokenChanger {


     
    function isToken(address _token) public view returns (bool);


     
    function getLeftToken() public view returns (address);


     
    function getRightToken() public view returns (address);


     
    function getFee() public view returns (uint);

    
     
    function getRate() public view returns (uint);


     
    function getPrecision() public view returns (uint);


     
    function calculateFee(uint _value) public view returns (uint);
}


 
contract TokenChanger is ITokenChanger, IPausable {

    IManagedToken private tokenLeft;  
    IManagedToken private tokenRight;  

    uint private rate;  
    uint private fee;  
    uint private precision;  
    bool private paused;  
    bool private burn;  


     
    modifier is_token(address _token) {
        require(_token == address(tokenLeft) || _token == address(tokenRight));
        _;
    }


     
    function TokenChanger(address _tokenLeft, address _tokenRight, uint _rate, uint _fee, uint _decimals, bool _paused, bool _burn) public {
        tokenLeft = IManagedToken(_tokenLeft);
        tokenRight = IManagedToken(_tokenRight);
        rate = _rate;
        fee = _fee;
        precision = _decimals > 0 ? 10**_decimals : 1;
        paused = _paused;
        burn = _burn;
    }

    
     
    function isToken(address _token) public view returns (bool) {
        return _token == address(tokenLeft) || _token == address(tokenRight);
    }


     
    function getLeftToken() public view returns (address) {
        return tokenLeft;
    }


     
    function getRightToken() public view returns (address) {
        return tokenRight;
    }


     
    function getFee() public view returns (uint) {
        return fee;
    }


     
    function getRate() public view returns (uint) {
        return rate;
    }


     
    function getPrecision() public view returns (uint) {
        return precision;
    }


     
    function isPaused() public view returns (bool) {
        return paused;
    }


     
    function pause() public {
        paused = true;
    }


     
    function resume() public {
        paused = false;
    }


     
    function calculateFee(uint _value) public view returns (uint) {
        return fee == 0 ? 0 : _value * fee / precision;
    }


     
    function convert(address _from, address _sender, uint _value) internal {
        require(!paused);
        require(_value > 0);

        uint amountToIssue;
        if (_from == address(tokenLeft)) {
            amountToIssue = _value * rate / precision;
            tokenRight.issue(_sender, amountToIssue - calculateFee(amountToIssue));
            if (burn) {
                tokenLeft.burn(this, _value);
            }   
        } 
        
        else if (_from == address(tokenRight)) {
            amountToIssue = _value * precision / rate;
            tokenLeft.issue(_sender, amountToIssue - calculateFee(amountToIssue));
            if (burn) {
                tokenRight.burn(this, _value);
            } 
        }
    }
}


 
contract KATMTokenChanger is TokenChanger, TokenObserver, TransferableOwnership, TokenRetriever, IAuthenticationManager {

    enum Stages {
        Deploying,
        Deployed
    }

    Stages public stage;

     
    IAuthenticator private authenticator;
    bool private requireAuthentication;


     
    modifier at_stage(Stages _stage) {
        require(stage == _stage);
        _;
    }


     
    modifier authenticate(address _account) {
        require(!requireAuthentication || authenticator.authenticate(_account));
        _;
    }


     
    function KATMTokenChanger(address _security, address _utility) public
        TokenChanger(_security, _utility, 8000, 500, 4, false, true) {
        stage = Stages.Deploying;
    }


     
    function setupWhitelist(address _authenticator, bool _requireAuthentication) public only_owner at_stage(Stages.Deploying) {
        authenticator = IAuthenticator(_authenticator);
        requireAuthentication = _requireAuthentication;
    }


     
    function deploy() public only_owner at_stage(Stages.Deploying) {
        stage = Stages.Deployed;
    }


     
    function isAuthenticating() public view returns (bool) {
        return requireAuthentication;
    }


     
    function enableAuthentication() public only_owner {
        requireAuthentication = true;
    }


     
    function disableAuthentication() public only_owner {
        requireAuthentication = false;
    }


     
    function pause() public only_owner {
        super.pause();
    }


     
    function resume() public only_owner {
        super.resume();
    }


     
    function onTokensReceived(address _token, address _from, uint _value) internal is_token(_token) authenticate(_from) at_stage(Stages.Deployed) {
        require(_token == msg.sender);
        
         
        convert(_token, _from, _value);
    }


     
    function retrieveTokens(address _tokenContract) public only_owner {
        super.retrieveTokens(_tokenContract);
    }


     
    function () public payable {
        revert();
    }
}