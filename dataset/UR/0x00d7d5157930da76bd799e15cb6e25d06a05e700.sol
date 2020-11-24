 

pragma solidity >=0.4.22 <0.6.0;

contract Airdrop {
    
    address payable chairman;
    mapping(address => Registrant) public registrants;
    mapping(uint256 => address) public registrantArr;
    uint256 public nRegistrants;
    mapping(bytes32 => address) nameToAddress;
    bool public registrationsOpen;
    uint256 public maxReferrals;
    address public maxReferrer;
    uint256 public totalClaims;
    uint256[4] public params;
    
    struct Registrant {
        bytes32 telegramHash;
        uint8 status;  
        bool verified;
        bool canClaim;
        bool created;
        address referrer;
        mapping (uint256 => address) referrals;
        uint256 nReferred;
        uint256 nReferredVerified;
    }
    
    Token token;
    address public tokenAddr = 0xd254fdE0eee65F3b75D01F5247bA260630A14B18;
    
    function claimTokens() external {
        require(registrationsOpen == false);
        require(totalClaims > 0);
        require(registrants[msg.sender].canClaim);
        token.transfer(msg.sender, canClaim(msg.sender) * token.balanceOf(address(this)) / totalClaims);
        registrants[msg.sender].status = 2;
    }
    
    function setVerification(bytes32 telegramHash, bool verification) external {
        require(msg.sender == chairman);
        require(registrationsOpen == false);
        if (!registrants[nameToAddress[telegramHash]].verified && verification) {
            registrants[nameToAddress[telegramHash]].verified = verification;
            registrants[registrants[nameToAddress[telegramHash]].referrer].nReferredVerified++;
            if (registrants[registrants[nameToAddress[telegramHash]].referrer].nReferredVerified > maxReferrals) {
                maxReferrals = registrants[registrants[nameToAddress[telegramHash]].referrer].nReferredVerified;
                maxReferrer = registrants[nameToAddress[telegramHash]].referrer;
            }
            return;
        }
        if (registrants[nameToAddress[telegramHash]].verified && !verification) {
            registrants[nameToAddress[telegramHash]].verified = verification;
            registrants[registrants[nameToAddress[telegramHash]].referrer].nReferredVerified--;
        }
    }
    
    function calcTotalClaims() public view returns(uint256) {
         
        uint256 res=0;
        for (uint256 i=0; i<nRegistrants; i++) {
            res += canClaim(registrantArr[i]); 
        }
        return res;
    }
    
    function calcStandardClaim() public view returns(uint256) {
        return 1000 * token.balanceOf(address(this)) / totalClaims;
    }
    
    function finishVerification() public {
        require(msg.sender == chairman);
        require(registrationsOpen == false);

        totalClaims = calcTotalClaims();
    }
    
    function finishVerificationManual(uint256 _totalClaims) public {
        require(msg.sender == chairman);
        require(registrationsOpen == false);

        totalClaims = _totalClaims;
    }
    function startVerification() public {
        require(msg.sender == chairman);
        registrationsOpen = false;
    }
    
    function canClaimtelegramHash(bytes32 telegramHash) external view returns(uint256) {
        return canClaim(nameToAddress[telegramHash]);
    }
    
    function canClaim(address addr) public view returns(uint256) {
        if (registrants[addr].status >= 2) {
            return 0;
        }
        if (!registrants[addr].verified) {
            return 0;
        }

        uint256 res = params[0];  
        for (uint256 i=0; i<registrants[addr].nReferred; i++) {
            if (registrants[registrants[addr].referrals[i]].verified) { 
                res += params[1];  
            }
            if (res >= params[2]) {  
                break;
            }
        }
        if (addr == maxReferrer) {
            res += params[3];  
        }
        return res;
    }
    
    function _register(address payable _addr, bytes32 referrer, bytes32 telegramHash) internal {
        require(registrationsOpen);
        require(_addr.balance > 100 finney, "100 finney minimum balance required");
        require(registrants[_addr].created == false, "already created");
        require(nameToAddress[telegramHash] == address(0x0), "telegramHash username already registered");
        require(nameToAddress[referrer] != address(0x0) || _addr == chairman, "must have referrer");

        nameToAddress[telegramHash] = _addr;
        registrants[_addr].status = 1;
        registrants[_addr].telegramHash = telegramHash;
        registrants[_addr].referrer = nameToAddress[referrer];
        registrants[_addr].verified = false;
        registrants[_addr].created = true;
        
        registrantArr[nRegistrants] = msg.sender;
        nRegistrants++;
        
        if (_addr == chairman) {
            return;
        }

        registrants[nameToAddress[referrer]].referrals[registrants[nameToAddress[referrer]].nReferred] = _addr;
        registrants[nameToAddress[referrer]].nReferred++;
    }
    
    function register(bytes32 referrer, bytes32 telegramHash) public {
        _register(msg.sender, referrer, telegramHash);
    }
    
    function registerManual(address payable _addr, bytes32 referrer, bytes32 telegramHash) public {
        require(msg.sender == chairman);
        _register(_addr, referrer, telegramHash);
    }
    
    
    function retrieveUnclaimed() external {
        require(msg.sender == chairman);
         
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
    
    function getAddress(bytes32 telegramHash) public view returns (address) {
        require(msg.sender == chairman);
        return nameToAddress[telegramHash];
    }
    
    
    function setParams(uint256[4] memory _params) public {
        require(msg.sender == chairman);
        params = _params;
    }
    
    constructor(bytes32 telegramHash) public {
        chairman = msg.sender;
        registrationsOpen = true;
        uint256[4] memory _params;
        _params[0] = 200;
        _params[1] = 400;
        _params[2] = 1000;
        _params[3] = 10000;
        setParams(_params);
        register(0, telegramHash);
        registrants[msg.sender].verified = true;
        token = Token(tokenAddr);
    }
} 

contract Token {
    mapping(address => uint256) public balanceOf;
    function transfer(address to, uint256 value) public returns (bool success) {

    }
}