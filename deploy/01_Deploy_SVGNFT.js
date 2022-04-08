let { networkConfig } = require("../helper-hardhat-config"); // importing networkConfig from helper file
const fs = require("fs");

module.exports = async ({
  getNamedAccounts, // hardhat deploy function that allows us to work with deployer
  deployments,
  getChainId, // helpful for testing vs testnets
}) => {
  const { deploy, log } = deployments; // getting deploy and log variables from deployments function
  const { deployer } = await getNamedAccounts(); // what getNamedAccounts does is, looking hardhat config for one of named accounts
  const chainId = await getChainId();
  // above lines bring functions log and deploy, as seen below

  log("----------------------------------------------------");
  const SVGNFT = await deploy("SVGNFT", {
    // this deploy bit knows all the contracts in contracts folder and itsgonna look for SVGNFT
    // And it will return from deployer/getNamedAccounts which is our zeroth account in metamask
    from: deployer, // deployer in config file
    log: true,
  });
  log(`You have deployed an NFT contract to ${SVGNFT.address}`);
  const svgNFTContract = await ethers.getContractFactory("SVGNFT"); // this gonna get us all the contract information about SVGNFT
  const accounts = await hre.ethers.getSigners(); // hre stands for hard path runtime environment built-in, grabs one of those accounts similar to deployer, didnt get this
  const signer = accounts[0]; // picking an account to sign our contracts
  const svgNFT = new ethers.Contract(
    SVGNFT.address,
    svgNFTContract.interface,
    signer
  );
  const networkName = networkConfig[chainId]["name"]; // the reason to grab network name is to verify our contract if we deploy on actual network

  log(
    `Verify with:\n npx hardhat verify --network ${networkName} ${svgNFT.address}`
  );
  log("Let's create an NFT now!");
  let filepath = "./img/small_enough.svg";
  let svg = fs.readFileSync(filepath, { encoding: "utf8" });
  log(
    `We will use ${filepath} as our SVG, and this will turn into a tokenURI. `
  );
  tx = await svgNFT.create(svg);
  await tx.wait(1);
  log(`You've made your first NFT!`);
  log(`You can view the tokenURI here ${await svgNFT.tokenURI(0)}`);
};

module.exports.tags = ["all", "svg"];
