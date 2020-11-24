 

pragma solidity 0.5.12;

contract AtaConstatacao {
    
     struct Requerente {
        string nomeTabeliao ;
        address enderecoRequerente;
        string unidadeFederativa;
        string cidade;
        string nomeCartorio;
        string numeroLivro;
        string numeroFolhaLivro;
    }
    
    mapping(address=>Requerente) public requerentes;
    
    
        
    function registro(
        string memory _nomeTabeliao, 
        string memory estado, 
        string memory cidade, 
        string memory cartorio, 
        string memory livro, 
        string memory folha) 
        public 
        returns (bool)
        {
        
        Requerente memory req=Requerente(_nomeTabeliao, msg.sender, estado, cidade, cartorio, livro, folha);
        requerentes[msg.sender]=req;
        return true;
    }
}