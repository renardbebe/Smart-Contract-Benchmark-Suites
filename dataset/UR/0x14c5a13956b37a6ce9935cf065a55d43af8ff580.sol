 

 

pragma solidity 0.5.4;


 
interface IGovernanceRegistry {
    
     
    function isSignee(address account) external view returns (bool);

     
    function isVault(address account) external view returns (bool) ;

}

 

pragma solidity 0.5.4;

 
interface IToken {

    function burn(uint256 amount) external ;

    function mint(address account, uint256 amount) external ;
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity 0.5.4;





 
contract Minter {

    using SafeMath for uint256;

    uint256 public index;

     
    event MintRequestCreated(
        address indexed vault, 
        uint256 indexed id, 
        address indexed receiver, 
        bytes32 barId,
        uint256 barSize,
        uint256 value
    );

     
    event MintRequestSigned(
        address indexed signer, 
        uint256 indexed id, 
        address indexed vault, 
        address receiver, 
        bytes32 barId,
        uint256 barSize,
        uint256 value
    );

     
    struct MintRequest{
         
        uint256 id;

         
        address receiver; 

         
        address vault;

         
        uint256 value;

         
        bytes32 barId;

         
        uint256 barSize;

         
        bool signed;
    }

     
    mapping (uint256 => MintRequest) public requests;

     
    IGovernanceRegistry public registry;

     
    IToken public token;

     
    constructor(IGovernanceRegistry governanceRegistry, IToken mintedToken) public {
        registry = governanceRegistry;
        token = mintedToken;
    }

     
    function createMintRequest(address receiver, bytes32 barId, uint256 barSize, uint256 value) onlyVault external {
        index = index.add(1);
        requests[index] = MintRequest(index, receiver, msg.sender, value, barId, barSize, false);
        emit MintRequestCreated(msg.sender, index, receiver, barId, barSize, value);
    }

     
    function signMintRequest(uint256 id) onlySignee external {
        MintRequest storage request = requests[id];
        require(!request.signed, "Request was signed previosuly");
        request.signed = true;
        token.mint(request.receiver, request.value);
        emit MintRequestSigned(
            msg.sender, 
            request.id, 
            request.vault, 
            request.receiver, 
            request.barId,
            request.barSize,
            request.value
        );
    }

     
    modifier onlyVault() {
        require(registry.isVault(msg.sender), "Caller is not a vault");
        _;
    }

     
    modifier onlySignee() {
        require(registry.isSignee(msg.sender), "Caller is not a signee");
        _;
    }

}