 

 

pragma solidity ^0.5.0;

 
 
 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 
 
 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

contract DC5ProofVerifier {
    function verifyProof(
      uint256[2]    memory a,
      uint256[2][2] memory b,
      uint256[2]    memory c,
      uint256[4]    memory input
    ) public view returns (bool r);
}

 

contract DC5 {
    using SafeMath for uint256;

     
    DC5ProofVerifier             public verifier;
    bytes32  			         public root;
    uint256                      public tokensPerScorePoint;
    address                      public nectarWallet;
    IERC20                       public nectarToken;
    address                      public relayer;

     
    mapping(uint256 => bool) 	 public nullifiers;

    constructor(
        address _verifier,
        address _nectarToken,
        address _nectarWallet,
        bytes32 _root,
        uint256 _tokensPerScorePoint,
        address _relayer
    ) public {
        verifier = DC5ProofVerifier(_verifier);
        nectarWallet = _nectarWallet;
        nectarToken = IERC20(_nectarToken);
        root = _root;
        tokensPerScorePoint = _tokensPerScorePoint;
        relayer = _relayer;
    }

    function withdraw(
        uint256[2]    calldata _a,
        uint256[2][2] calldata _b,
        uint256[2]    calldata _c,
        uint256       _nullifier,
        uint256       _score,
        address       _withdraw
    ) external {
        require(msg.sender==relayer,"only-relayer");
        
        require(!nullifiers[_nullifier],"nullifier-already-used");
        nullifiers[_nullifier] = true;

        uint256[4] memory input = [
        	_nullifier,
        	_score,
        	uint256(root),
        	uint256(_withdraw)
        ];

        require(
            verifier.verifyProof(_a,_b,_c,input),
            "cannot-verify-proof"
        );

        require(
            nectarToken.transferFrom(nectarWallet,_withdraw,_score.mul(tokensPerScorePoint)),
            "cannot-transfer-tokens"
        );
    }
}