 

 
 
 
 

 
 
 


pragma solidity ^0.4.18;

 

contract Ownable {
      address public        owner;


        event OwnershipTransferred (address indexed prevOwner, address indexed newOwner);

        function Ownable () public {
                owner       = msg.sender;
        }

        modifier onlyOwner () {
                require (msg.sender == owner);
                _;
        }

        function transferOwnership (address newOwner) public onlyOwner {
              require (newOwner != address (0));

              OwnershipTransferred (owner, newOwner);
              owner     = newOwner;
        }
}

 

 
library SafeMath {
        function add (uint256 a, uint256 b) internal pure returns (uint256) {
              uint256   c = a + b;
              assert (c >= a);
              return c;
        }

        function sub (uint256 a, uint256 b) internal pure returns (uint256) {
              assert (b <= a);
              return a - b;
        }

        function mul (uint256 a, uint256 b) internal pure returns (uint256) {
                if (a == 0) {
                        return 0;
                }
                uint256 c = a * b;
                assert (c/a == b);
                return c;
        }

         
         
         
         
         
         
         
}

 

 


 
contract ERC20 {
         
        function totalSupply () public view returns (uint256);
        function balanceOf (address tokenOwner) public view returns (uint256);
        function transfer (address to, uint256 amount) public returns (bool);
        event Transfer (address indexed from, address indexed to, uint256 amount);

         
        function allowance (address tokenOwner, address spender) public view returns (uint256);
        function approve (address spender, uint256 amount) public returns (bool);
        function transferFrom (address from, address to, uint256 amount) public returns (bool);
        event Approval (address indexed tokenOwner, address indexed spender, uint256 amount);
}


 

contract StandardToken is ERC20 {
        using SafeMath for uint256;

         
        uint256                             _tokenTotal;
        mapping (address => uint256)        _tokenBalances;

        function totalSupply () public view returns (uint256) {
                return _tokenTotal;
        }

        function balanceOf (address tokenOwner) public view returns (uint256) {
                return _tokenBalances[tokenOwner];
        }

        function _transfer (address to, uint256 amount) internal {
                 
                 
                _tokenBalances[msg.sender]      = _tokenBalances[msg.sender].sub (amount);
                _tokenBalances[to]              = _tokenBalances[to].add (amount);

                Transfer (msg.sender, to, amount);
        }

        function transfer (address to, uint256 amount) public returns (bool) {
                require (to != address (0));
                require (amount <= _tokenBalances[msg.sender]);      

                _transfer (to, amount);
                return true;
        }


         
        mapping (address => mapping (address => uint256)) internal  _tokenAllowance;

        function allowance (address tokenOwner, address spender) public view returns (uint256) {
                return _tokenAllowance[tokenOwner][spender];
        }

        function approve (address spender, uint256 amount) public returns (bool) {
                _tokenAllowance[msg.sender][spender]   = amount;
                Approval (msg.sender, spender, amount);
                return true;
        }

        function _transferFrom (address from, address to, uint256 amount) internal {
                 
                 
                _tokenBalances[from]    = _tokenBalances[from].sub (amount);
                _tokenBalances[to]      = _tokenBalances[to].add (amount);

                Transfer (from, to, amount);
        }

        function transferFrom (address from, address to, uint256 amount) public returns (bool) {
                require (to != address (0));
                require (amount <= _tokenBalances[from]);
                require (amount <= _tokenAllowance[from][msg.sender]);

                _transferFrom (from, to, amount);

                _tokenAllowance[from][msg.sender]     = _tokenAllowance[from][msg.sender].sub (amount);
                return true;
        }
}

 

 
 
 
 

 
 
 

pragma solidity ^0.4.18;





contract RSPScienceInterface {

        function isRSPScience() public pure returns (bool);
        function calcPoseBits (uint256 sek, uint256 posesek0, uint256 posesek1) public pure returns (uint256);
}


contract RockScissorPaper is StandardToken, Ownable {
        using SafeMath for uint256;

        string public   name                = 'RockScissorPaper';
        string public   symbol              = 'RSP';
        uint8 public    decimals            = 18;

        uint8 public    version             = 7;

         

        RSPScienceInterface public      rspScience;


        function _setRSPScienceAddress (address addr) internal {
                RSPScienceInterface     candidate   = RSPScienceInterface (addr);
                require (candidate.isRSPScience ());
                rspScience      = candidate;
        }

        function setRSPScienceAddress (address addr) public onlyOwner {
                _setRSPScienceAddress (addr);
        }

         
        function RockScissorPaper (address addr) public {
                 
                 
                 
                 

                if (addr != address(0)) {
                        _setRSPScienceAddress (addr);
                }
        }

        function () public payable {
                revert ();
        }


        mapping (address => uint256) public         weiInvested;
        mapping (address => uint256) public         weiRefunded;

        mapping (address => address) public         referrals;
        mapping (address => uint256) public         nRefs;
        mapping (address => uint256) public         weiFromRefs;

        event TokenInvest (address indexed purchaser, uint256 nWeis, uint256 nTokens, address referral);
        event TokenRefund (address indexed purchaser, uint256 nWeis, uint256 nTokens);

         
        function _mint (address tokenOwner, uint256 amount) internal {
                _tokenTotal                     = _tokenTotal.add (amount);
                _tokenBalances[tokenOwner]     += amount;    

                 
                Transfer (address (0), tokenOwner, amount);
        }

        function _burn (address tokenOwner, uint256 amount) internal {
                _tokenBalances[tokenOwner]  = _tokenBalances[tokenOwner].sub (amount);
                _tokenTotal                -= amount;        

                 
                Transfer (tokenOwner, address (0), amount);
        }

         
        function mint (uint256 amount) onlyOwner public {
                _mint (msg.sender, amount);
        }


        function buyTokens (address referral) public payable {
                 
                uint256     amount      = msg.value.mul (5000);
                require (amount >= 1 * 10**uint(decimals));

                 
                _mint (msg.sender, amount);

                if ( referrals[msg.sender] == address(0) &&
                     referral != msg.sender ) {
                        if (referral == address(0)) {
                                referral    = owner;
                        }

                        referrals[msg.sender]   = referral;
                        nRefs[referral]        += 1;
                }

                 
                weiInvested[msg.sender]    += msg.value;
                TokenInvest (msg.sender, msg.value, amount, referral);
        }

        function sellTokens (uint256 amount) public {
                _burn (msg.sender, amount);

                 
                uint256     nWeis   = amount / 5000;
                 

                 
                weiRefunded[msg.sender]     += nWeis;
                TokenRefund (msg.sender, nWeis, amount);

                msg.sender.transfer (nWeis);
        }



         
        struct GameRSP {
                address         creator;
                uint256         creatorPose;
                 
                uint256         nTokens;

                address         player;
                uint256         playerPose;
                uint256         sek;
                uint256         posebits;
        }


        GameRSP[]   games;
         

        function totalGames () public view returns (uint256) {
                return games.length;
        }

        function gameInfo (uint256 gameId) public view returns (address, uint256, uint256, address, uint256, uint256, uint256) {
                GameRSP storage     game    = games[gameId];

                return (
                    game.creator,
                    game.creatorPose,
                    game.nTokens,
                    game.player,
                    game.playerPose,
                    game.sek,
                    game.posebits
                );
        }


        uint8 public        ownerCut            = 5;                 
        uint8 public        referralCut         = 5;                 
        function changeFeeCut (uint8 ownCut, uint8 refCut) onlyOwner public {
                ownerCut        = ownCut;
                referralCut     = refCut;
        }


        event GameCreated (address indexed creator, uint256 gameId, uint256 pose);
        event GamePlayed (address indexed player, uint256 gameId, uint256 pose);
        event GameSolved (address indexed solver, uint256 gameId, uint256 posebits, address referral, uint256 solverFee);

        function createGame (uint256 amount, uint256 pose) public {
                 
                 
                require (_tokenBalances[msg.sender] >= amount);

                 
                require (amount >= 1 * 10**uint(decimals));


                 
                _transfer (this, amount);

                GameRSP memory      game    = GameRSP ({
                        creator:        msg.sender,
                        creatorPose:    pose,
                        nTokens:        amount,
                        player:         address (0),
                        playerPose:     0,
                        sek:            0,
                        posebits:       0
                });

                uint256     gameId          = games.push (game) - 1;

                 
                 
                 
                require (gameId == uint256(uint32(gameId)));
                GameCreated (msg.sender, gameId, pose);
        }


        function playGame (uint256 gameId, uint256 pose) public {
                GameRSP storage     game    = games[gameId];

                require (msg.sender != game.creator);
                require (game.player == address (0));

                uint256     nTokens = game.nTokens;
                 
                require (_tokenBalances[msg.sender] >= nTokens);

                 
                _transfer (this, nTokens);

                game.player         = msg.sender;
                game.playerPose     = pose;

                GamePlayed (msg.sender, gameId, pose);
        }

         
        function buyAndCreateGame (uint256 amount, uint256 pose, address referral) public payable {
                buyTokens (referral);
                createGame (amount, pose);
        }

        function buyAndPlayGame (uint256 gameId, uint256 pose, address referral) public payable {
                buyTokens (referral);
                playGame (gameId, pose);
        }


        function _solveGame (uint256 gameId, uint256 sek, uint256 solFee) public {
                GameRSP storage     game    = games[gameId];

                require (game.player != address (0));
                uint256     nTokens     = game.nTokens;

                require (_tokenBalances[this] >= nTokens * 2);

                uint256     ownerFee            = nTokens * 2 * ownerCut / 100;
                uint256     referralFee         = nTokens * 2 * referralCut / 100;
                uint256     winnerPrize         = nTokens * 2 - ownerFee - referralFee - solFee;
                uint256     drawPrize           = nTokens - solFee/2;

                require (game.sek == 0 && sek != 0);
                game.sek        = sek;

                address     referral;
                 
                uint256     posebits        = rspScience.calcPoseBits (sek, game.creatorPose, game.playerPose);

                 
                 
                if ((posebits % 9) == 0) {                                   
                        require (drawPrize >= 0);

                         
                        _transferFrom (this, game.creator, drawPrize);
                        _transferFrom (this, game.player, drawPrize);
                }
                else if ((posebits % 17) == 0 || posebits == 12) {           
                        require (winnerPrize >= 0);

                        referral            = referrals[game.creator];
                        if (referral == address(0)) {
                                referral    = owner;
                        }

                         
                        _transferFrom (this, game.creator, winnerPrize);
                        _transferFrom (this, referral, referralFee);
                        _transferFrom (this, owner, ownerFee);

                        weiFromRefs[referral]     += referralFee;
                }
                else if ((posebits % 10) == 0 || posebits == 33) {           
                        require (winnerPrize >= 0);

                        referral            = referrals[game.player];
                        if (referral == address(0)) {
                                referral    = owner;
                        }

                         
                        _transferFrom (this, game.player, winnerPrize);
                        _transferFrom (this, referral, referralFee);
                        _transferFrom (this, owner, ownerFee);

                        weiFromRefs[referral]     += referralFee;
                }

                if (solFee > 0) {
                        _transferFrom (this, msg.sender, solFee);
                }

                game.posebits    = posebits;
                GameSolved (msg.sender, gameId, game.posebits, referral, solFee);
        }



         
        function solveGame (uint256 gameId, uint256 sek) public {
                _solveGame (gameId, sek, 0);
        }

         
         
        function autoSolveGame (uint256 gameId, uint256 sek, uint256 solFee) onlyOwner public {
                _solveGame (gameId, sek, solFee);
        }

}