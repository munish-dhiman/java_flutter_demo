package dhiman.edu;

import io.quarkus.grpc.GrpcService;
import io.smallrye.mutiny.Uni;

@GrpcService
public class HelloGrpcService implements HelloGrpc {

	@Override
	public Uni<HelloReply> sayHello(final HelloRequest request) {
		return Uni.createFrom().item(createHelloMessage(request))
			.map(msg -> HelloReply.newBuilder().setMessage(msg).build());
	}

	private static String createHelloMessage(final HelloRequest request) {
		String name = request.hasName() ? request.getName() : "Anonymous";
		return "Hello " + name + "!";
	}

}
