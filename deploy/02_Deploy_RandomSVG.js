let {
  networkConfig,
  getNetworkIdFromName,
} = require("../helper-hardhat-config");
const fs = require("fs");

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy, get, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  // if we are not on local chain, we need below addresses stored somewhere
  let linkTokenAddress;
  let vrfCoordinatorAddress;

  if (chainId == 31337) {
    // this means we are on a local chain
    // if we are on local chain, we want to deploy those mocks we deployed earlier
    let linkToken = await get("LinkToken");
    let VRFCoordinatorMock = await get("VRFCoordinatorMock");
    linkTokenAddress = linkToken.address;
    vrfCoordinatorAddress = VRFCoordinatorMock.address;
    additionalMessage = " --linkaddress " + linkTokenAddress;
  } else {
    linkTokenAddress = networkConfig[chainId]["linkToken"];
    vrfCoordinatorAddress = networkConfig[chainId]["vrfCoordinator"];
  }

  // if we are local network, below details do not have to be in if state
  const keyHash = networkConfig[chainId]["keyHash"];
  const fee = networkConfig[chainId]["fee"];

  args = [vrfCoordinatorAddress, linkTokenAddress, keyHash, fee];
  log("----------------------------------------------------");
  // below line to deploy RandomSVG
  const RandomSVG = await deploy("RandomSVG", {
    from: deployer,
    args: args, // Taking args as arguments
    log: true,
  });
  log(`You have deployed an NFT contract to ${RandomSVG.address}`);

  // after deploying we need to verify our contract
  const networkName = networkConfig[chainId]["name"];
  log(
    `Verify with:\n npx hardhat verify --network ${networkName} ${
      RandomSVG.address
    } ${args.toString().replace(/,/g, " ")}`
  );

  // after verification we want to interact with the contract
  const RandomSVGContract = await ethers.getContractFactory("RandomSVG");
  const accounts = await hre.ethers.getSigners(); // gettting all signers/accounts
  const signer = accounts[0]; // picking the account to sign
  const randomSVG = new ethers.Contract( // getting randomSVG contract details
    RandomSVG.address,
    RandomSVGContract.interface,
    signer
  );

  // fund with LINK in order to interact with the contract
  let networkId = await getNetworkIdFromName(network.name);
  const fundAmount = networkConfig[networkId]["fundAmount"];
  const linkTokenContract = await ethers.getContractFactory("LinkToken"); // getting LinkToken contract among all contracts
  const linkToken = new ethers.Contract( // getting linkToken contract details
    linkTokenAddress,
    linkTokenContract.interface,
    signer
  );
  let fund_tx = await linkToken.transfer(RandomSVG.address, fundAmount); // transfering fundAmount to RandomSVG address
  await fund_tx.wait(1);

  // await new Promise(r => setTimeout(r, 5000))
  log("Let's create an NFT now!");
  let tokenId;
  if (chainId != 31337) {
    // First we setup up a listener, and then we call the create tx
    // This is so we can be sure to not miss it!
    const timeout = new Promise((res) => setTimeout(res, 300000)); //this is basically time.sleep in python
    // above we are giving time chainlink node to respond
    const listenForEvent = new Promise(async (resolve, reject) => {
      randomSVG.once("CreatedUnfinishedRandomSVG", async () => {
        tx = await randomSVG.finishMint(tokenId, { gasLimit: 2000000 });
        await tx.wait(1);
        log(`You can view the tokenURI here ${await randomSVG.tokenURI(0)}`);
        resolve();
      });
    });
    const result = Promise.race([timeout, listenForEvent]);
    tx = await randomSVG.create(
      { gasLimit: 300000 },
      { value: "100000000000000000" }
    );
    let receipt = await tx.wait(1); // with this receipt we are gonna grab the token id from return of create function
    tokenId = receipt.events[3].topics[2]; // knowing that 3rd event and 2nd topics are what we are looking for
    // topic 0 is hash of that event
    log(`You've made your NFT! This is number ${tokenId.toString()}`);
    log("Let's wait for the Chainlink VRF node to respond...");
    await result;
  } else {
    // if we are on local chain
    tx = await randomSVG.create({ gasLimit: 300000 });
    let receipt = await tx.wait(1);
    tokenId = receipt.events[3].topics[2];
    const VRFCoordinatorMock = await deployments.get("VRFCoordinatorMock"); // getting deployed VRFCoordinatorMock
    vrfCoordinator = await ethers.getContractAt(
      "VRFCoordinatorMock",
      VRFCoordinatorMock.address,
      signer
    );
    // we are gonna pretend to be the chainlink node and call callBackRandomness function since this function returns the random number
    let transactionResponse = await vrfCoordinator.callBackWithRandomness(
      receipt.logs[3].topics[1], // requestId
      77777, // random number
      randomSVG.address // address of the consumer contract which in our case SVG Contract
    );
    await transactionResponse.wait(1);
    log(`Now let's finish the mint...`);
    tx = await randomSVG.finishMint(tokenId, { gasLimit: 2000000 });
    await tx.wait(1);
  }
  log(`You can view the tokenURI here ${await randomSVG.tokenURI(0)}`);
};

module.exports.tags = ["all", "rsvg"];
