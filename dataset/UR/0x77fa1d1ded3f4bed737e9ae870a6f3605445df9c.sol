 

pragma solidity ^0.4.19;

 

library SafeMath {

 
function mul(uint256 a, uint256 b) internal pure returns (uint256) {
if (a == 0) {
return 0;
}
uint256 c = a * b;
assert(c / a == b);
return c;
}

 
function div(uint256 a, uint256 b) internal pure returns (uint256) {
 
uint256 c = a / b;
 
return c;
}

 
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
assert(b <= a);
return a - b;
}

 
function add(uint256 a, uint256 b) internal pure returns (uint256) {
uint256 c = a + b;
assert(c >= a);
return c;
}
}

contract CryptoPokemon {
using SafeMath for uint256;
mapping (address => bool) private admins;
mapping (uint => uint256) public levels;
mapping (uint => bool) private lock;
address contractCreator;
address devFeeAddress;
address tournamentPrizeAddress;

function CryptoPokemon () public {

contractCreator = msg.sender;
devFeeAddress = 0xFb2D26b0caa4C331bd0e101460ec9dbE0A4783A4;
tournamentPrizeAddress = 0xC6784e712229087fC91E0c77fcCb6b2F1fDE2Dc2;
admins[contractCreator] = true;
}

struct Pokemon {
string pokemonName;
address ownerAddress;
uint256 currentPrice;
}
Pokemon[] pokemons;

 
modifier onlyContractCreator() {
require (msg.sender == contractCreator);
_;
}
modifier onlyAdmins() {
require(admins[msg.sender]);
_;
}

 

 
function setOwner (address _owner) onlyContractCreator() public {
contractCreator = _owner;
}

function addAdmin (address _admin) onlyContractCreator() public {
admins[_admin] = true;
}

function removeAdmin (address _admin) onlyContractCreator() public {
delete admins[_admin];
}

 
function setdevFeeAddress (address _devFeeAddress) onlyContractCreator() public {
devFeeAddress = _devFeeAddress;
}

function settournamentPrizeAddress (address _tournamentPrizeAddress) onlyContractCreator() public {
tournamentPrizeAddress = _tournamentPrizeAddress;
}


bool isPaused;
 
function pauseGame() public onlyContractCreator {
isPaused = true;
}
function unPauseGame() public onlyContractCreator {
isPaused = false;
}
function GetGamestatus() public view returns(bool) {
return(isPaused);
}

function addLock (uint _pokemonId) onlyContractCreator() public {
lock[_pokemonId] = true;
}

function removeLock (uint _pokemonId) onlyContractCreator() public {
lock[_pokemonId] = false;
}

function getPokemonLock(uint _pokemonId) public view returns(bool) {
return(lock[_pokemonId]);
}

 
function purchasePokemon(uint _pokemonId) public payable {

 
require(msg.value >= pokemons[_pokemonId].currentPrice);
require(pokemons[_pokemonId].ownerAddress != address(0));
require(pokemons[_pokemonId].ownerAddress != msg.sender);
require(lock[_pokemonId] == false);
require(msg.sender != address(0));
require(isPaused == false);

 
address newOwner = msg.sender;
uint256 price = pokemons[_pokemonId].currentPrice;
uint256 excess = msg.value.sub(price);
uint256 realValue = pokemons[_pokemonId].currentPrice;

 
if (excess > 0) {
newOwner.transfer(excess);
}

 
uint256 cutFee = realValue.div(10);


 
uint256 commissionOwner = realValue - cutFee;  
pokemons[_pokemonId].ownerAddress.transfer(commissionOwner);

 
devFeeAddress.transfer(cutFee.div(2));  
tournamentPrizeAddress.transfer(cutFee.div(2));

 
pokemons[_pokemonId].ownerAddress = msg.sender;
pokemons[_pokemonId].currentPrice = pokemons[_pokemonId].currentPrice.mul(3).div(2);
levels[_pokemonId] = levels[_pokemonId] + 1;
}

 
function getPokemonDetails(uint _pokemonId) public view returns (
string pokemonName,
address ownerAddress,
uint256 currentPrice
) {
Pokemon storage _pokemon = pokemons[_pokemonId];

pokemonName = _pokemon.pokemonName;
ownerAddress = _pokemon.ownerAddress;
currentPrice = _pokemon.currentPrice;
}

 
function getPokemonCurrentPrice(uint _pokemonId) public view returns(uint256) {
return(pokemons[_pokemonId].currentPrice);
}

 
function getPokemonOwner(uint _pokemonId) public view returns(address) {
return(pokemons[_pokemonId].ownerAddress);
}

 
function getPokemonLevel(uint _pokemonId) public view returns(uint256) {
return(levels[_pokemonId]);
}

 
function deletePokemon(uint _pokemonId) public onlyContractCreator() {
delete pokemons[_pokemonId];
delete pokemons[_pokemonId];
delete lock[_pokemonId];
}

 
function setPokemon(uint _pokemonId, string _pokemonName, address _ownerAddress, uint256 _currentPrice, uint256 _levels) public onlyContractCreator() {
pokemons[_pokemonId].ownerAddress = _ownerAddress;
pokemons[_pokemonId].pokemonName = _pokemonName;
pokemons[_pokemonId].currentPrice = _currentPrice;

levels[_pokemonId] = _levels;
lock[_pokemonId] = false;
}

 
function addPokemon(string pokemonName, address ownerAddress, uint256 currentPrice) public onlyAdmins {
pokemons.push(Pokemon(pokemonName,ownerAddress,currentPrice));
levels[pokemons.length - 1] = 0;
lock[pokemons.length - 1] = false;
}

function totalSupply() public view returns (uint256 _totalSupply) {
return pokemons.length;
}

}